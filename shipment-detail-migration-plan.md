# Shipment Details Migration Plan

## Overview
Migrate shipment details and preview from Bulma modal to shadcn Sheet component with complete styling modernization while maintaining **EXACT** UI appearance and functionality.

## Migration Strategy
- **UI Testing After Every Step** - No progression until UI looks identical
- **Functionality Preservation** - All features must work exactly as before
- **Mobile Responsive Maintenance** - Keep existing responsive behavior, no major changes
- **Sticky Close Button** - Add shadcn cross button for mobile (sticky top-right corner)
- **Step-by-Step Validation** - Test each section individually before proceeding
- **Component Reuse** - Check existing shadcn components before creating new ones

## Files to Modify
1. **`/packages/core/modules/Shipments/shipment.tsx`** - In-place migration to shadcn
2. **`/packages/ui/components/shipment-preview-sheet.tsx`** - New Sheet component (replaces shipment-preview.tsx)
3. **`/packages/core/modules/Shipments/index.tsx`** - Update import statement

---

## Component Investigation Strategy

### Before Creating Any New Components:

1. **Check `/packages/ui/components/ui/` first** - Core shadcn components
2. **Check `/packages/ui/components/` second** - Custom project shadcn components  
3. **Check `/packages/ui/core/components/` third** - Legacy components to replace
4. **Create new only if needed** - Last resort

### Component Locations to Check:
```
/packages/ui/components/ui/           # Core shadcn primitives
/packages/ui/components/             # Custom shadcn components
/packages/ui/core/components/        # Legacy components (may need replacement)
```

### Investigation Required for Current Components:
- **StatusBadge** (`@karrio/ui/core/components/status-badge`) - Check if shadcn or needs replacement
- **CopiableLink** (`@karrio/ui/core/components/copiable-link`) - Check if shadcn or needs replacement
- **CarrierBadge** (`@karrio/ui/core/components/carrier-badge`) - Check if shadcn or needs replacement  
- **ShipmentMenu** (`@karrio/ui/core/components/shipment-menu`) - Check shadcn compatibility
- **InputField** (`@karrio/ui/core/components/input-field`) - Likely replace with shadcn Input
- **SelectField** (`@karrio/ui/core/components/select-field`) - Likely replace with shadcn Select
- **AddressDescription** - Check implementation
- **OptionsDescription** - Check implementation
- **ParcelDescription** - Check implementation
- **CommodityDescription** - Check implementation
- **CustomsInfoDescription** - Check implementation

---

## Phase 1: Migrate shipment.tsx to Shadcn (Top to Bottom)

> ⚠️ **TESTING REQUIREMENT**: After each step, verify UI looks identical and all functionality works

### Step 1: Header Section (Lines 114-148) ✅ **COMPLETED**
**Current Bulma Structure:**
```typescript
<div className="columns my-1">
  <div className="column is-6">
    <span className="subtitle is-size-7 has-text-weight-semibold">SHIPMENT</span>
    <span className="title is-4 mr-2">{shipment.tracking_number}</span>
    <StatusBadge status={shipment.status} />
  </div>
  <div className="column is-6 pb-0">
    <div className="is-flex is-justify-content-right">
      <CopiableLink text={shipment.id} title="Copy ID" />
    </div>
    <div className="is-flex is-justify-content-right">
      <ShipmentMenu shipment={shipment} isViewing />
    </div>
  </div>
</div>
```

**Convert to Shadcn/Tailwind:**
- `columns my-1` → `grid grid-cols-1 md:grid-cols-2 gap-4 my-1`
- `column is-6` → `space-y-2`
- `subtitle is-size-7 has-text-weight-semibold` → `text-sm font-semibold text-gray-600 uppercase tracking-wide`
- `title is-4` → `text-2xl font-semibold`
- `is-flex is-justify-content-right` → `flex justify-end`
- Maintain exact spacing and alignment

**Component Checks:**
- ✅ Use `ShipmentsStatusBadge` from `/packages/ui/components/shipments-status-badge.tsx` (already shadcn)
- ❓ Check if `CopiableLink` is shadcn compatible or needs replacement
- ✅ `ShipmentMenu` is already shadcn compatible

**🧪 Test Checklist:**
- [x] Header layout identical (two-column grid)
- [x] "SHIPMENT" label styled correctly (uppercase, small, semibold)
- [x] Tracking number displays with correct size and weight
- [x] ShipmentsStatusBadge displays correctly with proper colors
- [x] CopiableLink appears in top right and functions (with text + icon)
- [x] ShipmentMenu dropdown in bottom right works
- [x] External link button (if preview mode) works
- [x] **Mobile responsive**: Maintains existing responsive behavior
- [x] **Mobile responsive**: Maintains existing responsive behavior (removed cross button - only for preview sheet)

**✅ MIGRATION COMPLETED:**
- ✅ Created reusable `CopiableLink` component in `/packages/ui/components/copiable-link.tsx`
- ✅ Updated all imports to use shadcn components (`ShipmentsStatusBadge`, `ShipmentMenu`)
- ✅ Converted all Bulma classes to Tailwind/Shadcn equivalents
- ✅ Preserved all existing functionality while modernizing architecture
- ✅ Removed sticky close button (will be handled only in preview sheet during Phase 2)

---

### Step 2: Reference and Highlights Section (Lines 152-215) ✅ **COMPLETED**
**Current Bulma Structure:**
```typescript
<div className="columns mb-4">
  <div className="p-4 mr-4">
    <span className="subtitle is-size-7 my-4">Date</span>
    <br />
    <span className="subtitle is-size-7 mt-1 has-text-weight-semibold">
      {formatDateTime(shipment.created_at)}
    </span>
  </div>

  {!isNone(shipment.service) && (
    <>
      <div className="my-2" style={{ width: "1px", backgroundColor: "#ddd" }}></div>
      <div className="p-4 mr-4">
        <span className="subtitle is-size-7 my-4">Courier</span>
        <br />
        <CarrierBadge
          className="has-background-primary has-text-centered has-text-weight-bold has-text-white-bis is-size-7"
          carrier_name={shipment.meta.carrier}
          text_color={shipment.selected_rate_carrier?.config?.text_color}
          background={shipment.selected_rate_carrier?.config?.brand_color}
        />
      </div>
      {/* Similar structure for Service Level and Reference */}
    </>
  )}
</div>
```

**Final Implementation:**
```typescript
<hr className="mt-1 mb-0" style={{ height: "1px" }} />

{/* Reference and highlights section */}
<div className="flex flex-col md:flex-row md:flex-wrap gap-0 mb-4">
  <div className="p-4 mr-4">
    <span className="text-xs text-gray-600 my-4">Date</span>
    <br />
    <span className="text-xs mt-1 font-semibold">
      {formatDateTime(shipment.created_at)}
    </span>
  </div>

  {!isNone(shipment.service) && (
    <>
      <div className="hidden md:block w-px bg-gray-300 my-1"></div>
      <div className="p-4 mr-4">
        <span className="text-xs text-gray-600 my-4">Courier</span>
        <br />
        <CarrierBadge
          carrier_name={shipment.meta.carrier as string}
          text_color={shipment.selected_rate_carrier?.config?.text_color}
          background={shipment.selected_rate_carrier?.config?.brand_color}
        />
      </div>
      {/* Similar pattern for Service Level and Reference */}
    </>
  )}
</div>
```

**Key Changes from Original Plan:**
- ✅ `columns mb-4` → `flex flex-col md:flex-row md:flex-wrap gap-0 mb-4`
- ✅ `subtitle is-size-7` → `text-xs text-gray-600` (corrected from text-sm)
- ✅ Vertical dividers: `w-px bg-gray-300 my-1` (adjusted from my-2 for better spacing)
- ✅ Mobile responsive: `flex-col` stacks items, `hidden md:block` hides dividers on mobile
- ✅ Horizontal rule: `mb-2` → `mb-0` for better spacing alignment
- ✅ CarrierBadge confirmed compatible (no className changes needed)

**Component Checks:**
- ✅ `CarrierBadge` is compatible (removed unnecessary className props)
- ✅ Custom carrier colors work correctly

**🧪 Test Checklist:**
- [x] Horizontal layout with proper spacing on desktop
- [x] Vertical stacking on mobile (no dividers)
- [x] Date section displays correctly with proper text size
- [x] Vertical dividers properly spaced (`my-1`)
- [x] Courier badge shows with proper brand colors
- [x] Service level text matches original styling
- [x] Reference displays when exists
- [x] Conditional rendering works for all sections
- [x] **Mobile responsive**: Perfect mobile stacking behavior maintained

**✅ MIGRATION COMPLETED:**
- ✅ Converted Bulma columns to responsive Tailwind flex layout
- ✅ Maintained exact text sizes with `text-xs` (matching `is-size-7`)
- ✅ Perfect mobile stacking behavior (vertical on mobile, horizontal on desktop)
- ✅ Proper vertical divider spacing with `my-1`
- ✅ All conditional rendering preserved (service, reference sections)
- ✅ CarrierBadge custom colors working correctly

---

### Step 3: Service Details Section (Lines 217-303)
**Current Bulma Structure:**
```typescript
<h2 className="title is-5 my-4">Service Details</h2>
<hr className="mt-1 mb-2" style={{ height: "1px" }} />

<div className="mt-3 mb-6">
  <div className="columns my-0 py-1">
    <div className="column is-6 is-size-6">
      <div className="columns my-0">
        <div className="column is-4 is-size-6 py-1">Service</div>
        <div className="column is-size-6 has-text-weight-semibold py-1">
          {formatRef(((shipment.meta as any)?.service_name || shipment.service))}
        </div>
      </div>
      {/* Similar structure for Courier, Rate, Rate Provider, Tracking Number */}
    </div>

    {(shipment.selected_rate?.extra_charges || []).length > 0 && (
      <div className="column is-6 is-size-6 py-1">
        <p className="is-title is-size-6 my-2 has-text-weight-semibold">CHARGES</p>
        <hr className="mt-1 mb-2" style={{ height: "1px" }} />
        {/* Charges mapping */}
      </div>
    )}
  </div>
</div>
```

**Convert to Shadcn/Tailwind:**
- `title is-5` → `text-xl font-semibold`
- `hr` with custom height → `border-t border-gray-200`
- `columns my-0 py-1` → `grid grid-cols-1 md:grid-cols-2 gap-6 py-1`
- `column is-6` → Grid column spans
- `column is-4` → `w-1/3` (maintaining 4/12 ratio)
- `is-size-6` → `text-base`
- `has-text-weight-semibold` → `font-semibold`
- `is-title is-size-6 my-2 has-text-weight-semibold` → `text-base font-semibold uppercase tracking-wide my-2`

**🧪 Test Checklist:**
- [ ] "Service Details" header looks identical (size, weight, spacing)
- [ ] Horizontal rule below header matches
- [ ] Two-column layout matches original (service info left, charges right)
- [ ] Service info rows align correctly (label left, value right)
- [ ] Service, Courier, Rate values display correctly
- [ ] Rate Provider text appears in blue/info color
- [ ] Tracking number displays correctly
- [ ] Charges section displays properly (if exists)
- [ ] All currency and rate values show correctly
- [ ] Conditional rendering works for charges section
- [ ] **Mobile responsive**: Maintains existing mobile layout and stacking behavior

---

### Step 4: Tracking Details Section (Lines 305-375)
**Current Bulma Structure:**
```typescript
<h2 className="title is-5 my-4">
  <span>Tracking Details</span>
  <a className="p-0 mx-2 my-0 is-size-6 has-text-weight-semibold"
     href={`/tracking/${shipment.tracker_id}`}
     target="_blank" rel="noreferrer">
    <span><i className="fas fa-external-link-alt"></i></span>
  </a>
</h2>
<hr className="mt-1 mb-2" style={{ height: "1px" }} />

<div className="mt-3 mb-6">
  <div className="columns my-0 py-1">
    <div className="column is-6 is-size-7">
      {!isNone(shipment.tracker?.estimated_delivery) && (
        <div className="columns my-0">
          <div className="column is-4 is-size-6 py-0">
            {shipment.tracker?.delivered ? "Delivered" : "Estimated Delivery"}
          </div>
          <div className="column has-text-weight-semibold py-1">
            {formatDayDate(shipment.tracker!.estimated_delivery)}
          </div>
        </div>
      )}
      {/* Similar structure for Last event, Location, Description */}
    </div>
  </div>
</div>
```

**Convert to Shadcn/Tailwind:**
- Header with external link icon conversion
- Same grid layout patterns as previous sections
- External link with FontAwesome icon → use Lucide icon or maintain FontAwesome
- `is-size-7` → `text-sm`
- `has-text-weight-semibold` → `font-semibold`

**🧪 Test Checklist:**
- [ ] Header with external link icon positioned correctly
- [ ] External tracking link works and opens in new tab
- [ ] Estimated delivery date displays correctly
- [ ] "Delivered" vs "Estimated Delivery" label logic works
- [ ] Last event date and time display correctly
- [ ] Location information shows (if available)
- [ ] Event description appears (if available)
- [ ] Conditional rendering works (only shows if tracker exists)
- [ ] All date formatting matches original
- [ ] **Mobile responsive**: Maintains existing mobile layout behavior

---

### Step 5: Shipment Details Section (Lines 377-498)
**Current Bulma Structure:**
```typescript
<h2 className="title is-5 my-4">Shipment Details</h2>
<hr className="mt-1 mb-2" style={{ height: "1px" }} />

<div className="mt-3 mb-6">
  <div className="columns my-0">
    {/* Recipient Address section */}
    <div className="column is-6 is-size-6 py-1">
      <p className="is-title is-size-6 my-2 has-text-weight-semibold">ADDRESS</p>
      <AddressDescription address={shipment.recipient} />
    </div>

    {/* Options section */}
    {Object.values(shipment.options as object).length > 0 && (
      <div className="column is-6 is-size-6 py-1">
        <p className="is-title is-size-6 my-2 has-text-weight-semibold">OPTIONS</p>
        <OptionsDescription options={shipment.options} />
      </div>
    )}
  </div>

  {/* Parcels section */}
  <div className="mt-6 mb-0">
    <p className="is-title is-size-6 my-2 has-text-weight-semibold">
      PARCEL{shipment.parcels.length > 1 && "S"}
    </p>

    {shipment.parcels.map((parcel, index) => (
      <React.Fragment key={index + "parcel-info"}>
        <hr className="my-4" style={{ height: "1px" }} />
        <div className="columns mb-0 is-multiline">
          {/* Parcel details */}
          <div className="column is-6 is-size-6 py-1">
            <ParcelDescription parcel={parcel} />
          </div>
          {/* Parcel items */}
          {(parcel.items || []).length > 0 && (
            <div className="column is-6 is-size-6 py-1">
              <p className="is-title is-size-6 my-2 has-text-weight-semibold">
                ITEMS <span className="is-size-7">({totalQuantity})</span>
              </p>
              <div className="menu-list py-2 pr-1" style={{ maxHeight: "40em", overflow: "auto" }}>
                {parcel.items.map((item, index) => (
                  <React.Fragment key={index + "item-info"}>
                    <hr className="mt-1 mb-2" style={{ height: "1px" }} />
                    <CommodityDescription commodity={item} />
                  </React.Fragment>
                ))}
              </div>
            </div>
          )}
        </div>
      </React.Fragment>
    ))}
  </div>

  {/* Customs section */}
  <div className="columns mt-6 mb-0 is-multiline">
    {!isNone(shipment.customs) && (
      <div className="column is-6 is-size-6 py-1">
        <p className="is-title is-size-6 my-2 has-text-weight-semibold">CUSTOMS DECLARATION</p>
        <CustomsInfoDescription customs={shipment.customs} />
      </div>
    )}
    {/* Customs commodities similar structure */}
  </div>
</div>
```

**Convert to Shadcn/Tailwind:**
- Grid layouts for ADDRESS and OPTIONS
- Parcels section with proper spacing
- Items listing with scroll area using shadcn `ScrollArea` component
- Customs declaration and commodities sections
- `menu-list` with scroll → shadcn `ScrollArea` with `max-h-[40rem] overflow-auto`

**Component Checks Required:**
- Check if `AddressDescription` is shadcn compatible
- Check if `OptionsDescription` is shadcn compatible  
- Check if `ParcelDescription` is shadcn compatible
- Check if `CommodityDescription` is shadcn compatible
- Check if `CustomsInfoDescription` is shadcn compatible

**🧪 Test Checklist:**
- [ ] "Shipment Details" header styling matches
- [ ] Address section displays correctly
- [ ] Options section shows all shipping options (if exists)
- [ ] Parcel(s) header handles singular/plural correctly
- [ ] Each parcel information displays properly
- [ ] Items list scrolls properly with 40em max height
- [ ] Items quantity count shows correctly in parentheses
- [ ] Customs declaration shows (for international shipments)
- [ ] Customs commodities list displays correctly
- [ ] All spacing and alignment matches original
- [ ] Conditional rendering works for all sections
- [ ] **Mobile responsive**: Maintains existing mobile layout and stacking behavior

---

### Step 6: Document Section (Lines 500-612)
**Current Bulma Structure:**
```typescript
{((carrier_capabilities[shipment.carrier_name] || []) as any).includes("paperless") &&
  "paperless_trade" in shipment.options && (
    <>
      <h2 className="title is-5 my-4">Paperless Trade Documents</h2>

      {!documents.isFetched && documents.isFetching && <Spinner />}

      {documents.isFetched && [...uploads, ...docFiles].length == 0 && (
        <>
          <hr className="mt-1 mb-3" style={{ height: "1px" }} />
          <div className="pb-3">No documents uploaded</div>
        </>
      )}

      {documents.isFetched && [...uploads, ...docFiles].length > 0 && (
        <div className="table-container">
          <table className="related-item-table table is-hoverable is-fullwidth">
            <tbody>
              {uploads.map((upload) => (
                // Document rows
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="is-flex is-justify-content-space-between">
        <div className="is-flex">
          <SelectField onChange={...} defaultValue="other" className="is-small is-fullwidth">
            <option value="other">other</option>
            <option value="commercial_invoice">Commercial invoice</option>
            {/* More options */}
          </SelectField>
          <InputField className="is-small mx-2" type="file" onChange={handleFileChange} />
        </div>
        <button className="button is-default is-small" onClick={uploadCustomsDocument}>
          <span className="icon is-small"><i className="fas fa-upload"></i></span>
          <span>Upload</span>
        </button>
      </div>
    </>
  )
}
```

**Convert to Shadcn/Tailwind:**
- `table is-hoverable is-fullwidth` → Use shadcn `Table, TableHeader, TableBody, TableRow, TableCell`
- `SelectField` → shadcn `Select, SelectContent, SelectItem, SelectTrigger, SelectValue`
- `InputField` → shadcn `Input`
- `button is-default is-small` → shadcn `Button` with appropriate size and variant
- `is-flex is-justify-content-space-between` → `flex justify-between`
- `Spinner` → Check if existing shadcn spinner is available

**Component Checks:**
- Check `/packages/ui/components/ui/table.tsx`
- Check `/packages/ui/components/ui/select.tsx`  
- Check `/packages/ui/components/ui/input.tsx`
- Check `/packages/ui/components/ui/button.tsx`
- Check for existing Spinner component

**🧪 Test Checklist:**
- [ ] Section only shows for carriers with paperless capability
- [ ] "Paperless Trade Documents" header styling correct
- [ ] Loading spinner shows while fetching
- [ ] "No documents uploaded" message displays when empty
- [ ] Documents table displays correctly with hover effects
- [ ] Document rows show file names and "uploaded" status
- [ ] Document type dropdown works (other, commercial_invoice, etc.)
- [ ] File selection input works
- [ ] Upload button functions correctly
- [ ] Upload button shows loading state during upload
- [ ] Success/error notifications appear after upload
- [ ] Button disabled states work correctly
- [ ] **Mobile responsive**: Maintains existing mobile table and form behavior

---

### Step 7: Metadata Section (Lines 614-644)
**Current Bulma Structure:**
```typescript
<MetadataEditor id={shipment.id} object_type={MetadataObjectTypeEnum.shipment} metadata={shipment.metadata}>
  <MetadataEditorContext.Consumer>
    {({ isEditing, editMetadata }) => (
      <>
        <div className="is-flex is-justify-content-space-between">
          <h2 className="title is-5 my-4">Metadata</h2>
          <button
            type="button"
            className="button is-default is-small is-align-self-center"
            disabled={isEditing}
            onClick={() => editMetadata()}
          >
            <span className="icon is-small"><i className="fas fa-pen"></i></span>
            <span>Edit metadata</span>
          </button>
        </div>
        <hr className="mt-1 mb-2" style={{ height: "1px" }} />
      </>
    )}
  </MetadataEditorContext.Consumer>
</MetadataEditor>
```

**Convert to Shadcn/Tailwind:**
- `is-flex is-justify-content-space-between` → `flex justify-between items-center`
- `button is-default is-small is-align-self-center` → shadcn `Button` with size="sm" and variant="outline"
- `title is-5` → `text-xl font-semibold`
- FontAwesome pen icon → Lucide `Pencil` icon or maintain FontAwesome
- Maintain `MetadataEditor` integration (likely already shadcn)

**Component Checks:**
- Verify `MetadataEditor` is shadcn compatible
- Check available icon system (Lucide vs FontAwesome)

**🧪 Test Checklist:**
- [ ] Header and button flex layout correct with proper alignment
- [ ] "Metadata" header styling matches other section headers
- [ ] Edit metadata button styled correctly with icon
- [ ] Button disabled state works when editing
- [ ] Edit metadata button functionality works
- [ ] MetadataEditor opens and functions properly
- [ ] Metadata displays correctly when not editing
- [ ] Save/cancel functionality works in metadata editor
- [ ] **Mobile responsive**: Maintains existing mobile layout behavior

---

### Step 8: Make Component Sheet-Compatible
**Requirements:**
- Must work identically in both full page and sheet contexts
- Proper responsive behavior in constrained sheet width (800px)
- Add sticky close button for mobile (both preview and detail page)
- No layout breaking or horizontal scrolling

**Modifications Needed:**
```typescript
// Add prop to indicate sheet context
interface ShipmentComponentProps {
  shipmentId: string;
  isPreview?: boolean;
  isSheet?: boolean; // New prop
  showMobileCloseButton?: boolean; // New prop for sticky close button
}

// Add sticky close button for mobile
const StickyCloseButton = ({ onClose }: { onClose: () => void }) => (
  <button
    onClick={onClose}
    className="fixed top-4 right-4 z-50 md:hidden bg-white rounded-full p-2 shadow-lg border"
  >
    <X className="h-4 w-4" />
  </button>
);

// Conditional styling based on context
const containerClasses = isSheet 
  ? "max-w-none" // Allow full sheet width
  : "container mx-auto"; // Normal page constraints
```

**Testing in Constrained Width:**
- Test all grid layouts at 800px width
- Ensure tables don't overflow
- Check that long text content wraps properly
- Verify mobile responsive behavior still works

**🧪 Test Checklist:**
- [ ] Full page display unchanged
- [ ] Component renders properly in 800px width constraint  
- [ ] All grid layouts work in sheet context
- [ ] Tables fit within sheet width
- [ ] No horizontal scrolling in sheet
- [ ] Text content wraps appropriately
- [ ] All interactive elements accessible and clickable
- [ ] Proper padding/margins in sheet context
- [ ] **Mobile responsive**: Maintains existing responsive behavior
- [ ] **Sticky close button**: Close button appears in top-right corner on mobile
- [ ] **Close button functionality**: Sticky close button works for both preview and detail page
- [ ] **Close button styling**: Button has proper shadow, border, and positioning

---

## Phase 2: Create New Sheet Component

> 📖 **Reference Implementation**: Use `/packages/core/modules/ShippingRules/index.tsx` as reference for how Sheet components should work with proper integration, styling, and behavior patterns.

### Step 1: Create `/packages/ui/components/shipment-preview-sheet.tsx`

**Component Structure:**
```typescript
"use client";
import { ShipmentComponent } from "@karrio/core/modules/Shipments/shipment";
import { 
  Sheet, 
  SheetContent, 
  SheetHeader, 
  SheetTitle,
  SheetDescription 
} from "@karrio/ui/components/ui/sheet";
import { useLocation } from "@karrio/hooks/location";
import { X } from "lucide-react";
import React, { useState } from "react";

type ShipmentPreviewSheetContextType = {
  previewShipment: (shipmentId: string) => void;
};

interface ShipmentPreviewSheetComponent {
  children?: React.ReactNode;
}

export const ShipmentPreviewSheetContext = React.createContext<ShipmentPreviewSheetContextType>(
  {} as ShipmentPreviewSheetContextType,
);

export const ShipmentPreviewSheet = ({ children }: ShipmentPreviewSheetComponent): JSX.Element => {
  const { addUrlParam, removeUrlParam } = useLocation();
  const [isActive, setIsActive] = useState<boolean>(false);
  const [key, setKey] = useState<string>(`shipment-${Date.now()}`);
  const [shipmentId, setShipmentId] = useState<string>();

  const previewShipment = (shipmentId: string) => {
    setShipmentId(shipmentId);
    setIsActive(true);
    setKey(`shipment-${Date.now()}`);
    addUrlParam("modal", shipmentId);
  };

  const dismiss = (_?: any) => {
    setShipmentId(undefined);
    setIsActive(false);
    setKey(`shipment-${Date.now()}`);
    removeUrlParam("modal");
  };

  return (
    <>
      <ShipmentPreviewSheetContext.Provider value={{ previewShipment }}>
        {children}
      </ShipmentPreviewSheetContext.Provider>

      <Sheet open={isActive} onOpenChange={(open) => !open && dismiss()}>
        <SheetContent className="w-full sm:w-[800px] sm:max-w-[800px] p-0 overflow-y-auto" side="right">
          <div className="sticky top-0 bg-background border-b p-4 z-10">
            <div className="flex items-center justify-between">
              <div>
                <SheetTitle>Shipment Details</SheetTitle>
                <SheetDescription>View shipment information and tracking details</SheetDescription>
              </div>
            </div>
          </div>
          
          {isActive && shipmentId && (
            <div className="p-6 relative">
              <ShipmentComponent 
                shipmentId={shipmentId} 
                isPreview={true}
                isSheet={true}
                showMobileCloseButton={true}
                onMobileClose={dismiss}
              />
            </div>
          )}
        </SheetContent>
      </Sheet>
    </>
  );
};
```

**Features to Maintain:**
- Same `previewShipment(shipmentId)` function signature
- Same context provider API
- URL parameter management (`modal` param)  
- Same dismiss functionality
- Key-based re-rendering for fresh data

**🧪 Test Checklist:**
- [ ] Sheet opens when clicking shipment table rows
- [ ] Sheet slides smoothly from right side
- [ ] Close button (X) works in top-right corner
- [ ] Click outside sheet to close works
- [ ] Escape key closes sheet
- [ ] URL parameters update correctly (modal=shipmentId)
- [ ] URL parameters clear when closing
- [ ] Context functions work identically to original
- [ ] Sheet title and description display correctly
- [ ] **Mobile responsive**: Sheet maintains existing responsive behavior
- [ ] **Sticky close button**: Mobile close button appears and functions correctly

---

### Step 2: Sheet Configuration & Styling

**Sheet Settings:**
- **Width**: `w-full sm:w-[800px] sm:max-w-[800px]` - Full width on mobile, 800px on larger screens
- **Side**: `right` (default) - Slides in from right
- **Overflow**: `overflow-y-auto` - Scrollable content
- **Padding**: `p-0` on SheetContent, `p-6` on inner content
- **Sticky Header**: Fixed header with title while scrolling

**Header Design:**
```typescript
<div className="sticky top-0 bg-background border-b p-4 z-10">
  <div className="flex items-center justify-between">
    <div>
      <SheetTitle>Shipment Details</SheetTitle>
      <SheetDescription>View shipment information and tracking details</SheetDescription>
    </div>
  </div>
</div>
```

**Content Area:**
```typescript
<div className="p-6">
  <ShipmentComponent 
    shipmentId={shipmentId} 
    isPreview={true}
    isSheet={true}
  />
</div>
```

**🧪 Test Checklist:**
- [ ] Sheet width appropriate on all screen sizes
- [ ] Slides in smoothly with proper animation
- [ ] Overlay appears with correct opacity
- [ ] Close animations are smooth
- [ ] Sticky header stays fixed while scrolling
- [ ] Content scrolls properly without header moving
- [ ] No performance issues during open/close
- [ ] Proper z-index layering
- [ ] Background blur/overlay works correctly
- [ ] **Mobile responsive**: Maintains existing responsive behavior  
- [ ] **Mobile performance**: No performance degradation on mobile devices

---

### Step 3: Update Integration Points

**File: `/packages/core/modules/Shipments/index.tsx`**

**Changes Required:**
```typescript
// Old import
import {
  ShipmentPreview,
  ShipmentPreviewContext,
} from "@karrio/core/components/shipment-preview";

// New import
import {
  ShipmentPreviewSheet,
  ShipmentPreviewSheetContext,
} from "@karrio/ui/components/shipment-preview-sheet";

// Update context usage
const { previewShipment } = useContext(ShipmentPreviewSheetContext);

// Update component wrapper (at bottom of component)
return (
  <ShipmentPreviewSheet>
    <Component />
  </ShipmentPreviewSheet>
);
```

**Verify Integration Points:**
- All table cell click handlers still call `previewShipment(shipment.id)`
- Context is properly consumed in component
- No other files import the old `shipment-preview` component

**🧪 Test Checklist:**
- [ ] Shipment table loads without errors
- [ ] All table cells are clickable (service, status, recipient, reference, date)
- [ ] Clicking any table cell opens the sheet
- [ ] Sheet displays correct shipment data
- [ ] No console errors during sheet operations
- [ ] Performance is unchanged from original modal
- [ ] All existing functionality preserved
- [ ] Table selection/checkboxes still work
- [ ] Pagination and filtering unaffected
- [ ] **Mobile responsive**: Maintains existing mobile table behavior

---

## Testing Strategy & Protocols

### Phase 1 Testing (After Each Step):

#### Visual Verification:
- [ ] **Side-by-Side Comparison**: Open original and new version simultaneously
- [ ] **Pixel-Perfect Match**: Headers, spacing, colors, fonts identical  
- [ ] **Responsive Layout**: Test mobile, tablet, desktop breakpoints
- [ ] **Typography**: Font sizes, weights, colors match exactly
- [ ] **Spacing**: Margins, paddings, gaps identical
- [ ] **Mobile Visual Check**: Maintains existing mobile design
- [ ] **Sticky Close Button**: Mobile close button visible and properly positioned

#### Functionality Testing:
- [ ] **Data Display**: All shipment information appears correctly
- [ ] **Interactive Elements**: Buttons, links, dropdowns work
- [ ] **Forms**: File upload, metadata editing function
- [ ] **External Links**: Tracking links, shipment page links work
- [ ] **Conditional Logic**: Sections show/hide based on data
- [ ] **Mobile Touch**: Maintains existing touch interaction behavior
- [ ] **Mobile Close Button**: Sticky close button responds to touch correctly

#### Performance Testing:
- [ ] **Load Time**: No degradation in page load speed
- [ ] **Memory Usage**: No memory leaks during component updates
- [ ] **Smooth Animations**: Any transitions remain smooth
- [ ] **Mobile Performance**: Maintains existing mobile performance

### Phase 2 Testing (Sheet Component):

#### Sheet Behavior:
- [ ] **Opening Animation**: Smooth slide-in from right
- [ ] **Closing Animation**: Smooth slide-out to right
- [ ] **Overlay**: Proper background overlay with blur/opacity
- [ ] **Multiple Opens**: Handle rapid opening/closing without issues

#### Content Display:
- [ ] **Full Information**: All shipment details visible in sheet
- [ ] **Scrolling**: Proper scroll behavior with sticky header
- [ ] **Responsive**: Works on all device sizes
- [ ] **Width Constraints**: Content fits properly in 800px width
- [ ] **Mobile Sheet**: Maintains existing mobile sheet behavior

#### Interaction Testing:
- [ ] **All Clickables**: Every button/link works within sheet
- [ ] **Form Submission**: File uploads work from within sheet
- [ ] **External Navigation**: Links properly open in new tabs
- [ ] **Context Menus**: Dropdown menus work within sheet constraints
- [ ] **Mobile Sheet**: Maintains existing mobile interaction behavior

### Integration Testing:

#### Backward Compatibility:
- [ ] **Existing Routes**: Direct shipment URLs still work
- [ ] **API Calls**: All data fetching unchanged
- [ ] **Error Handling**: Error states display correctly
- [ ] **Loading States**: Spinners and loading indicators work

#### Cross-Browser Testing:
- [ ] **Chrome**: All functionality works
- [ ] **Firefox**: All functionality works  
- [ ] **Safari**: All functionality works
- [ ] **Edge**: All functionality works
- [ ] **Mobile Browsers**: Touch interactions work

#### Performance Integration:
- [ ] **Table Performance**: Shipment list loading unchanged
- [ ] **Sheet Performance**: Opening/closing is fast
- [ ] **Memory Management**: No memory leaks over time
- [ ] **Bundle Size**: No significant increase in build size

---

## Migration Execution Order

### Development Sequence:
1. **Phase 1, Step 1**: Header section → Complete testing → Commit
2. **Phase 1, Step 2**: References section → Complete testing → Commit
3. **Phase 1, Step 3**: Service details → Complete testing → Commit
4. **Phase 1, Step 4**: Tracking details → Complete testing → Commit  
5. **Phase 1, Step 5**: Shipment details → Complete testing → Commit
6. **Phase 1, Step 6**: Documents section → Complete testing → Commit
7. **Phase 1, Step 7**: Metadata section → Complete testing → Commit
8. **Phase 1, Step 8**: Sheet compatibility → Complete testing → Commit
9. **Phase 2, Step 1**: Create sheet component → Complete testing → Commit
10. **Phase 2, Step 2**: Sheet configuration → Complete testing → Commit
11. **Phase 2, Step 3**: Integration → Complete testing → Commit

### Testing Protocol for Each Step:
1. **Complete Implementation** - Finish coding the step
2. **Visual Verification** - Compare with original side-by-side
3. **Functionality Testing** - Test all interactive elements
4. **Responsive Testing** - Verify mobile/tablet/desktop
5. **Performance Check** - Ensure no degradation
6. **Pass All Checklists** - Complete step-specific checklist
7. **Commit Changes** - Save progress before next step

### No Progression Rule:
- **DO NOT PROCEED** to next step until current step passes all tests
- **ROLL BACK** if any issues found that break existing functionality
- **DOCUMENT** any deviations from original design for review

---

## Component Replacement Reference

### Bulma to Shadcn/Tailwind Conversion Guide:

#### Layout Classes:
```typescript
// Bulma → Tailwind
"columns" → "grid grid-cols-1 md:grid-cols-2 gap-4"
"column is-6" → "col-span-1" 
"column is-4" → "w-1/3"
"is-flex" → "flex"
"is-justify-content-space-between" → "justify-between"
"is-justify-content-right" → "justify-end"
"is-align-self-center" → "self-center"
```

#### Typography Classes:
```typescript
// Bulma → Tailwind
"title is-4" → "text-2xl font-semibold"
"title is-5" → "text-xl font-semibold"
"subtitle is-size-6" → "text-base font-medium"
"subtitle is-size-7" → "text-sm"
"is-size-6" → "text-base"
"is-size-7" → "text-sm"
"has-text-weight-semibold" → "font-semibold"
"has-text-weight-bold" → "font-bold"
"is-capitalized" → "capitalize"
"has-text-info" → "text-blue-600"
"has-text-grey" → "text-gray-500"
```

#### Component Classes:
```typescript
// Bulma → Shadcn
"button is-default is-small" → <Button variant="outline" size="sm">
"button is-white" → <Button variant="ghost">
"tag is-success" → <Badge variant="success">
"table is-hoverable is-fullwidth" → <Table> with hover styles
```

#### Spacing Classes:
```typescript
// Bulma → Tailwind
"my-4" → "my-4" (same)
"p-4" → "p-4" (same)
"mr-4" → "mr-4" (same)
"pb-0" → "pb-0" (same)
"mt-1 mb-2" → "mt-1 mb-2" (same)
```

---

## Rollback Strategy

### Backup Plan:
1. **Keep Original File**: Rename `shipment-preview.tsx` to `shipment-preview-legacy.tsx`
2. **Version Control**: Commit after each successful step
3. **Feature Flag**: If available, use feature flag for gradual rollout
4. **Quick Revert**: Can restore import statements in under 5 minutes

### Rollback Triggers:
- Any critical functionality broken
- Performance degradation > 20%
- UI significantly different from original
- User-reported issues in production

### Rollback Process:
1. **Immediate**: Revert import statements in `index.tsx`
2. **Short-term**: Restore original component files
3. **Documentation**: Document issues found for future attempts

---

## Success Criteria

### Must Achieve:
- ✅ **Identical UI**: Pixel-perfect visual match with original
- ✅ **Full Functionality**: All features work exactly as before
- ✅ **Performance**: No degradation in load times or responsiveness  
- ✅ **Accessibility**: All interactive elements remain accessible
- ✅ **Mobile**: Perfect responsive behavior maintained
- ✅ **Clean Code**: Modern shadcn/Tailwind implementation
- ✅ **Maintainability**: Code is cleaner and easier to maintain
- ✅ **Reusability**: Component works in both sheet and full page contexts

### Quality Gates:
- All test checklists must pass ✅
- No console errors or warnings ✅
- Bundle size increase < 5% ✅
- All browser compatibility maintained ✅
- Mobile performance unchanged ✅

---

## Notes & Considerations

### Development Tips:
- Use browser dev tools to compare exact pixel measurements
- Test with real shipment data, not just mock data
- Pay special attention to conditional rendering logic
- Maintain exact spacing using Tailwind's spacing scale
- Use shadcn components exactly as intended (don't customize heavily)

### Common Pitfalls to Avoid:
- Changing spacing or layout subtly (must be exact)
- Breaking responsive behavior on mobile
- Losing hover states or interactive feedback
- Breaking keyboard navigation
- Forgetting to test edge cases (empty data, very long text, etc.)

### Future Enhancements:
After successful migration, consider:
- Dark mode support (shadcn makes this easier)
- Better loading states  
- Enhanced accessibility features
- Performance optimizations
- Additional responsive breakpoints