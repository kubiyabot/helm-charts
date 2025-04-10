# Changelog

## v0.3.0 - 2024-12-23

Forked dagger subchart to support kubiya-runner. Moved additional resources implemented within `kubiya-runner` required for it's support to the fork.

## v0.13.6 - 2024-10-24


### Dependencies
- Bump Engine to v0.13.6 by @jedevc in https://github.com/dagger/dagger/pull/8770

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.13.5 - 2024-10-10


### Dependencies
- Bump Engine to v0.13.5 by @sipsma in https://github.com/dagger/dagger/pull/8679

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.13.4 - 2024-10-09


### Dependencies
- Bump Engine to v0.13.4 by @jedevc in https://github.com/dagger/dagger/pull/8661

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.13.3 - 2024-09-20


### Dependencies
- Bump Engine to v0.13.3 by @vito in https://github.com/dagger/dagger/pull/8523

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.13.2 - 2024-09-20


### Dependencies
- Bump Engine to v0.13.2 by @vito in https://github.com/dagger/dagger/pull/8514

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.13.1 - 2024-09-18


### Dependencies
- Bump Engine to v0.13.1 by @sipsma in https://github.com/dagger/dagger/pull/8488

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.13.0 - 2024-09-11


### 🔥 Breaking Changes
- Remove `appVersion` - this is now the chart version by @gerhard in https://github.com/dagger/dagger/pull/8348 \
  Customizing the Engine image is now done via `engine.image.ref` and requires
  the full image reference, including the registry URL. If you configure this
  value, you must ensure that this Engine image is compatible with the chart.
- Removes default `oci-max-parallelism` `num-cpu` Engine setting by @gerhard in https://github.com/dagger/dagger/pull/8406
  This option is known to be problematic in certain scenarios 

### Dependencies
- Bump Engine to v0.13.0 by @jedevc in https://github.com/dagger/dagger/pull/8408

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.12.7 - 2024-09-02


### Dependencies
- Bump Engine to v0.12.7 by @jedevc in https://github.com/dagger/dagger/pull/8299

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.12.6 - 2024-08-29


### Changed
- Use `dagger query` for engine healthcheck by @matipan in https://github.com/dagger/dagger/pull/8219

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.12.5 - 2024-08-15


### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.12.4 - 2024-08-01


### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.12.3 - 2024-07-25


### Dependencies
- Bump Engine to v0.12.3 by @github-actions in https://github.com/dagger/dagger/pull/8039

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.12.2 - 2024-07-22


### Dependencies
- Bump Engine to v0.12.2 by @github-actions in https://github.com/dagger/dagger/pull/8006

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.12.1 - 2024-07-18


### Dependencies
- Bump Engine to v0.12.1 by @github-actions in https://github.com/dagger/dagger/pull/7978

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)



## v0.12.0 - 2024-07-12


### Changed
- Align app version with chart version by @gerhard in https://github.com/dagger/dagger/pull/7854

### Dependencies
- Bump Engine to v0.12.0 by @github-actions in https://github.com/dagger/dagger/pull/7903

### What to do next?
- Read the [documentation](https://docs.dagger.io)
- Join our [Discord server](https://discord.gg/dagger-io)
- Follow us on [Twitter](https://twitter.com/dagger_io)
