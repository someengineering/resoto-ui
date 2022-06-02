# `ui`
resoto UI prototype


## Table of contents

* [Overview](#overview)
* [How to get the UI running](#overview)
    * [Importing your cloud data into the UI](#importing-your-cloud-data-into-the-ui)
* [Contact](#contact)
* [License](#license)


## Overview
This serves to communicate the vision we work on for the resoto UI.
At the moment, this is just a prototype with no functionality except the visual rendition of an exported resoto Graph and some fancy UI elements.

**Our goals for this and the upcoming releases**
 - Establishing a basic navigation concept.
 - Trying to rethink the dashboard from a display tool to a deeply connected entry point.
 - Find an intuitive way of integrating the resoto query language.
 - Exploring ways of displaying the graph and give the user intuitive tools to navigate it.
 - Having fun exploring the cloud environment.
 - Easy and useful ways of searching the graph and integrate queries into this concept.


## How to get the UI running
The UI ships as part of the Resoto Docker image and will be available at `<resotocore-address>:8900/ui/`.

**To build the standalone version follow these steps:**
- Download [Godot 3.4](https://godotengine.org/download) (standard version).
- Start the engine and import the project in the Project Manager (click import, select the 'project.godot' file).
- Open the project from the Project Manager.
- Run the Project by clicking on the "Play" button in the upper right corner.
- Enter your resotocore URI in the provided field and load the graph.


## Contact
If you have any questions feel free to [join our Discord](https://discord.gg/someengineering) or [open a GitHub issue](https://github.com/someengineering/resoto/issues/new).


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
