# `Resoto UI`

## Table of contents

* [Overview](#overview)
* [How to get the UI running](#overview)
* [Join the Community](#contact)
* [License](#license)


## Overview
First things first: This readme is still very short. We are working on full-on documentation for the UI right now.

Resoto UI is a web-based WASM application that runs in most browsers (we recommend Chrome) and was built using the [Godot Engine](https://godotengine.org/).
The Resoto UI connects to a running Resoto Core - so if you want to use the UI, [you need Resoto first](https://github.com/someengineering/resoto).

**The UI has four main features to make using Resoto easier:**
- Customizable dashboards (Historic data via Prometheus and live data via Resoto)
- Exploring your infrastructure via search. Navigate via fast and easy navigation.
- Change your Resoto configuration via a comfortable and powerful configuration editor
- Have simple and fast access to the Resoto Shell via a Terminal emulator (very basic though)

Of course, we already work on more features, especially rendering and navigating a visual graph!


## How to use the Resoto UI
The UI ships as part of the [Resoto Docker](https://resoto.com/docs/getting-started/install-resoto/docker) image and is then served at `<resotocore-address>:8900/ui/`.

**To use a standalone version follow these steps:**
- Download [Godot 3.5](https://godotengine.org/download) (standard version).
- Start the engine and import the project in the Project Manager (click import, select the 'project.godot' file).
- Open the project from the Project Manager.
- Run the Project by clicking on the `Play` button in the upper right corner or by pressing `F5`.


## Contact
[Join our Discord](https://discord.gg/someengineering) if you have any questions or want to chat about Resoto or Resoto UI - or [open a GitHub issue](https://github.com/someengineering/resoto-ui/issues/new) if you encounter problems and/or bugs.


## License
```
Copyright 2022 Some Engineering Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
