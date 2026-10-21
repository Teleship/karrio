# ECS CPU and memory

The root Makefile supplies `TASK_CPU` in ECS CPU units (1024 = 1 vCPU) and
`TASK_MEMORY` in MiB per task. The task templates require both inputs with
[`must_env`](https://github.com/kayac/ecspresso/tree/v2.8.7#template-syntax).
Task fields remain JSON strings. Container fields remain JSON integers.

| Service / template directory | Sandbox CPU / MiB | Production CPU / MiB |
| --- | --- | --- |
| `karrio-api` / `api` | 1024 / 2048 | 1024 / 3072 |
| `karrio-worker` / `worker` | 1024 / 2048 | 1024 / 2048 |
| `karrio-dashboard` / `dashboard` | 256 / 512 | 256 / 512 |

These values follow the 19 October 2026 cost audit. API and worker CPU stay at
1024 because observed peaks reached 100%. Production API memory uses 3072 MiB
because observed use reached approximately 60% of 4096 MiB.

Each task has one container, no sidecars, and no memory reservation. Container CPU
and hard memory limits use the task inputs. If you add a sidecar, allocate its
resources within the task budget. Worker concurrency remains unchanged.

Use `make <command>_<environment>_<service>` from the repository root:

- Commands: `render`, `diff`, `verify`, `deploy`.
- Environments: `sandbox`, `production`.
- Services: `api`, `worker`, `dashboard`.

For example, `make render_production_api` renders the production API task.
All four commands use the same environment-specific inputs. Worker targets use
the API image. To override an allocation, use named Makefile variables:

```sh
make render_production_api PRODUCTION_KARRIO_API_TASK_CPU=1024 PRODUCTION_KARRIO_API_TASK_MEMORY=4096
```

Direct ecspresso calls must supply `TASK_CPU`, `TASK_MEMORY`, and `IMAGE_URI`.
Missing or empty resource inputs stop rendering. No resource defaults are set
in the templates. Use the Makefile targets to select the environment values.

`render` reads the configured Terraform state. `diff` also reads ECS state.
`verify` checks AWS resources with secret retrieval and log writes disabled.
These commands require the selected AWS profile. `deploy` changes ECS and must
only be run with deployment authorisation.

The allocations follow the [AWS Fargate task CPU/memory table](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html)
and [container resource parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html).
