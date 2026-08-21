"""SmartKargo carrier rate tests."""

import unittest
from unittest.mock import patch, ANY
from .fixture import gateway
import logging
import karrio.sdk as karrio
import karrio.lib as lib
import karrio.core.models as models

logger = logging.getLogger(__name__)


class TestSmartKargoRating(unittest.TestCase):
    def setUp(self):
        self.maxDiff = None
        self.RateRequest = models.RateRequest(**RatePayload)

    def test_create_rate_request(self):
        request = gateway.mapper.create_rate_request(self.RateRequest)
        self.assertEqual(lib.to_dict(request.serialize()), RateRequestData)

    def _custom_items(self, payload: dict) -> list:
        """The customItems SmartKargo actually receives, after serialization.

        Asserted on the serialized payload rather than the DTO because the
        omit-when-absent behaviour these cases turn on lives in lib.to_dict's
        empty-value filter, not in the mapper: the DTO carries None for every
        absent field either way.
        """
        request = gateway.mapper.create_rate_request(models.RateRequest(**payload))

        return lib.to_dict(request.serialize())[0]["packages"][0]["customItems"]

    def test_create_rate_request_with_cpsc_exemption(self):
        """A disclaimed line sends the exemption and no certificate identifiers.

        This is the TEL-312 shipment: SmartKargo rejected it because customItems
        reached the carrier with zero CPSC fields.
        """
        self.assertListEqual(
            self._custom_items(
                {**RatePayload, "customs": _cpsc_customs(CpscExemptionMetadata)}
            ),
            [{**CustomItemBase, "cpscShipperExemptionDeclaration": True}],
        )

    def test_create_rate_request_with_cpsc_certificate(self):
        """A certified line sends the trio and no exemption declaration."""
        self.assertListEqual(
            self._custom_items(
                {**RatePayload, "customs": _cpsc_customs(CpscCertificateMetadata)}
            ),
            [{**CustomItemBase, **CpscCertificateFields}],
        )

    def test_create_rate_request_with_cpsc_certificate_and_exemption(self):
        """Given both, the certificate wins and the exemption is dropped.

        Filing a real certificate is never less compliant than disclaiming one,
        whereas disclaiming while a certificate exists is the risky direction.
        """
        self.assertListEqual(
            self._custom_items(
                {
                    **RatePayload,
                    "customs": _cpsc_customs(
                        {**CpscCertificateMetadata, **CpscExemptionMetadata}
                    ),
                }
            ),
            [{**CustomItemBase, **CpscCertificateFields}],
        )

    def test_create_rate_request_with_partial_cpsc_certificate_and_exemption(self):
        """One identifier is enough to drop the exemption.

        The ticket states the precedence rule twice and the two statements disagree
        on partial input. This pins the reading implemented: the trio and the
        exemption are never emitted together, unconditionally.
        """
        self.assertListEqual(
            self._custom_items(
                {
                    **RatePayload,
                    "customs": _cpsc_customs(
                        {
                            "cpsc_certifier_id": "CERT12345678",
                            **CpscExemptionMetadata,
                        }
                    ),
                }
            ),
            [{**CustomItemBase, "cpscCertifierId": "CERT12345678"}],
        )

    def test_create_rate_request_ignores_non_identifier_cpsc_values(self):
        """A non-identifier must not masquerade as a certificate.

        Metadata is unvalidated JSON, so a client writing `cpscCertifierId ?? 0` sends
        an integer 0, and a GTIN mishandled as a number arrives as a float. Coercing
        either would file a bogus certifier id and - because any identifier suppresses
        the exemption - silently drop the merchant's real declaration, reproducing
        TEL-312 for the only data shape currently in production. A genuine integer
        identifier is still accepted; see the numeric case below.
        """
        for value in [0, 1.5, 12345678901234.0, True, False, [], {}, "", "   "]:
            with self.subTest(certifier_id=value):
                self.assertListEqual(
                    self._custom_items(
                        {
                            **RatePayload,
                            "customs": _cpsc_customs(
                                {
                                    "cpsc_certifier_id": value,
                                    **CpscExemptionMetadata,
                                }
                            ),
                        }
                    ),
                    [{**CustomItemBase, "cpscShipperExemptionDeclaration": True}],
                )

    def test_create_rate_request_accepts_numeric_cpsc_identifier(self):
        """A numeric GTIN or UPC is a legitimate identifier, not a sentinel."""
        self.assertListEqual(
            self._custom_items(
                {
                    **RatePayload,
                    "customs": _cpsc_customs({"cpsc_product_id": 12345678901234}),
                }
            ),
            [{**CustomItemBase, "cpscProductId": "12345678901234"}],
        )

    def test_create_rate_request_does_not_truncate_cpsc_identifier(self):
        """An identifier goes out exactly as given, for SmartKargo to judge.

        Truncating to the spec's 19 characters would produce a different,
        well-formed-looking certifier id that SmartKargo accepts - a mis-filed
        certificate is worse than a rejected booking. The fixture is deliberately
        awkward - 56 characters, mixed case, a run of inner spaces, six kinds of
        punctuation - so that any normalization at all fails this test, not only the
        truncation the docstring names, and not only at the bounds the spec happens
        to mention.
        """
        self.assertListEqual(
            self._custom_items(
                {
                    **RatePayload,
                    "customs": _cpsc_customs(
                        {"cpsc_certifier_id": "Cert/1234  5678-9012.3456.7890_abcd+EFGH~ijkl(mnop)qrst."}
                    ),
                }
            ),
            [{**CustomItemBase, "cpscCertifierId": "Cert/1234  5678-9012.3456.7890_abcd+EFGH~ijkl(mnop)qrst."}],
        )

    def test_create_rate_request_trims_only_surrounding_whitespace(self):
        """Surrounding whitespace is dropped; the value itself is untouched.

        Tabs and newlines count as surrounding whitespace, not only spaces.
        """
        self.assertListEqual(
            self._custom_items(
                {
                    **RatePayload,
                    "customs": _cpsc_customs({"cpsc_certifier_id": " \t CERT12345678 \n "}),
                }
            ),
            [{**CustomItemBase, "cpscCertifierId": "CERT12345678"}],
        )

    def test_create_rate_request_ignores_non_boolean_cpsc_exemption(self):
        """Only a real boolean true declares an exemption.

        Reading the flag by truthiness would turn the string "false" into a positive
        compliance declaration, and comparing with == would do the same for an integer
        1 - which a shipper storing booleans as 0/1 will send. Losing a declaration
        earns a loud SmartKargo rejection; asserting one that was never made does not.
        """
        for value in ["false", "true", "True", 1, 1.0, 0]:
            with self.subTest(exemption=value):
                self.assertListEqual(
                    self._custom_items(
                        {
                            **RatePayload,
                            "customs": _cpsc_customs(
                                {"cpsc_shipper_exemption_declaration": value}
                            ),
                        }
                    ),
                    [CustomItemBase],
                )

    def test_get_rates(self):
        with patch("karrio.mappers.smartkargo.proxy.lib.request") as mock:
            mock.return_value = "{}"
            karrio.Rating.fetch(self.RateRequest).from_(gateway)
            self.assertEqual(
                mock.call_args[1]["url"],
                f"{gateway.settings.server_url}/quotation",
            )

    def test_parse_rate_response(self):
        with patch("karrio.mappers.smartkargo.proxy.lib.request") as mock:
            mock.return_value = RateResponse
            parsed_response = (
                karrio.Rating.fetch(self.RateRequest).from_(gateway).parse()
            )
            self.assertListEqual(
                lib.to_dict(parsed_response),
                ParsedRateResponse,
            )

    def test_parse_error_response(self):
        with patch("karrio.mappers.smartkargo.proxy.lib.request") as mock:
            mock.return_value = ErrorResponse
            parsed_response = (
                karrio.Rating.fetch(self.RateRequest).from_(gateway).parse()
            )
            self.assertListEqual(
                lib.to_dict(parsed_response),
                ParsedErrorResponse,
            )


if __name__ == "__main__":
    unittest.main()


def _cpsc_customs(metadata: dict) -> dict:
    """Customs payload for one CPSC-flagged commodity carrying the given metadata.

    Mirrors the line that triggered TEL-312: a CPSC-regulated HTS on a commercial
    service, where the merchant answered the compliance question.
    """
    return {
        "commodities": [
            {
                "sku": "SKU-HOODIE-1",
                "hs_code": "6110202015",
                "quantity": 1,
                "weight": 0.45,
                "weight_unit": "KG",
                "description": "The Ellie Oversized Hoodie",
                "value_amount": 86.0,
                "value_currency": "USD",
                "origin_country": "CN",
                "metadata": metadata,
            }
        ],
        "incoterm": "DDU",
    }


# The non-CPSC keys every case below shares. Spelled out rather than abbreviated so
# that an unexpected extra key fails the assertion, which is the point: this change's
# whole risk is a single mis-keyed field name.
CustomItemBase = {
    "commercialValue": 86.0,
    "commercialValueCurrency": "USD",
    "description": "The Ellie Oversized Hoodie",
    "exportHsCode": "6110202015",
    "importHsCode": "6110202015",
    "manufactureCountryCode": "CN",
    "quantity": 1,
    "quantityUnit": "KG",
    "sku": "SKU-HOODIE-1",
    "weight": 0.45,
}

CpscExemptionMetadata = {"cpsc_shipper_exemption_declaration": True}
CpscCertificateMetadata = {
    "cpsc_certifier_id": "CERT12345678",
    "cpsc_product_id": "PROD98765432",
    "cpsc_certificate_version_id": "VER-2",
}
CpscCertificateFields = {
    "cpscCertifierId": "CERT12345678",
    "cpscProductId": "PROD98765432",
    "cpscCertificateVersionId": "VER-2",
}


RatePayload = {
    "shipper": {
        "address_line1": "1 Broadway",
        "city": "Boston",
        "postal_code": "02142",
        "country_code": "US",
        "state_code": "MA",
        "person_name": "TESTER TEST",
        "company_name": "Test Company",
        "phone_number": "19999999999",
        "email": "test@test.com",
    },
    "recipient": {
        "address_line1": "124 Main St",
        "city": "Los Angeles",
        "postal_code": "98148",
        "country_code": "US",
        "state_code": "CA",
        "person_name": "Tester Tester",
        "phone_number": "8888347867",
        "email": "test2@test.com",
    },
    "parcels": [
        {
            "weight": 10.0,
            "width": 20.0,
            "height": 20.0,
            "length": 20.0,
            "weight_unit": "KG",
            "dimension_unit": "CM",
            "reference_number": "PKG-TEST-001",
        }
    ],
    "reference": "RATE-REQ-001",
}

RateRequestData = [
    {
        "issueDate": ANY,
        "packages": [
            {
                "commodityType": "9999",
                "insuranceAmmount": 0.0,
                "dimensions": [
                    {
                        "grossWeight": 10.0,
                        "height": 20.0,
                        "length": 20.0,
                        "pieces": 1,
                        "width": 20.0,
                    }
                ],
                "grossVolumeUnityMeasure": "CMQ",
                "grossWeightUnityMeasure": "KG",
                "hasInsurance": False,
                "packageDescription": "General Shipment",
                "participants": [
                    {
                        "account": "TEST_ACCOUNT",
                        "additionalId": "TEST_ID",
                        "city": "Boston",
                        "countryId": "US",
                        "email": "test@test.com",
                        "name": "Test Company",
                        "phoneNumber": "19999999999",
                        "postCode": "02142",
                        "primaryId": "TEST_ID",
                        "state": "MA",
                        "street": "1 Broadway",
                        "type": "Shipper",
                    },
                    {
                        "city": "Los Angeles",
                        "countryId": "US",
                        "email": "test2@test.com",
                        "name": "Tester Tester",
                        "phoneNumber": "8888347867",
                        "postCode": "98148",
                        "state": "CA",
                        "street": "124 Main St",
                        "type": "Consignee",
                    },
                ],
                "paymentMode": "PX",
                "reference": "PKG-TEST-001",
                "totalGrossWeight": 10.0,
                "totalPackages": 1,
                "totalPieces": 1,
            }
        ],
        "reference": "RATE-REQ-001",
    }
]

RateResponse = """{
  "headerReference": "30068480254",
  "packageReference": "PKG-36780746",
  "status": "Quoted",
  "details": [
    {
      "slaInDays": 3,
      "deliveryDateBasedOnShipment": "2021-06-07T21:00:00+00:00",
      "serviceType": "EXP",
      "total": 12.00,
      "totalTax": 1.15
    },
    {
      "slaInDays": 5,
      "deliveryDateBasedOnShipment": "2021-06-09T21:00:00+00:00",
      "serviceType": "EPR",
      "total": 10.00,
      "totalTax": 1.19
    },
    {
      "slaInDays": 6,
      "deliveryDateBasedOnShipment": "2021-06-10T21:00:00+00:00",
      "serviceType": "EST",
      "total": 8.00,
      "totalTax": 1.15
    }
  ],
  "validations": null
}"""

ErrorResponse = """{
  "status": "Failed",
  "validations": [
    {
      "code": "VAL001",
      "message": "Invalid origin address"
    }
  ]
}"""

ParsedRateResponse = [
    [
        {
            "carrier_id": "smartkargo",
            "carrier_name": "smartkargo",
            "currency": "USD",
            "extra_charges": [
                {"amount": 12.0, "currency": "USD", "name": "Base Rate"},
                {"amount": 1.15, "currency": "USD", "name": "Tax"},
            ],
            "meta": {
                "estimated_delivery": "2021-06-07T21:00:00+00:00",
                "service_name": "smartkargo_express",
                "service_type": "EXP",
            },
            "service": "smartkargo_express",
            "total_charge": 13.15,
            "transit_days": 3,
        },
        {
            "carrier_id": "smartkargo",
            "carrier_name": "smartkargo",
            "currency": "USD",
            "extra_charges": [
                {"amount": 10.0, "currency": "USD", "name": "Base Rate"},
                {"amount": 1.19, "currency": "USD", "name": "Tax"},
            ],
            "meta": {
                "estimated_delivery": "2021-06-09T21:00:00+00:00",
                "service_name": "smartkargo_priority",
                "service_type": "EPR",
            },
            "service": "smartkargo_priority",
            "total_charge": 11.19,
            "transit_days": 5,
        },
        {
            "carrier_id": "smartkargo",
            "carrier_name": "smartkargo",
            "currency": "USD",
            "extra_charges": [
                {"amount": 8.0, "currency": "USD", "name": "Base Rate"},
                {"amount": 1.15, "currency": "USD", "name": "Tax"},
            ],
            "meta": {
                "estimated_delivery": "2021-06-10T21:00:00+00:00",
                "service_name": "smartkargo_standard",
                "service_type": "EST",
            },
            "service": "smartkargo_standard",
            "total_charge": 9.15,
            "transit_days": 6,
        },
    ],
    [],
]

ParsedErrorResponse = [
    [],
    [
        {
            "carrier_id": "smartkargo",
            "carrier_name": "smartkargo",
            "code": "VAL001",
            "details": {},
            "message": "Invalid origin address",
        },
    ],
]
