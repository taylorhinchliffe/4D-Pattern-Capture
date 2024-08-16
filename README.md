# 4D Pattern Capture

## Description:
This is a simple prototype MacOS SceneKit+Metal application that uses GPU-accelerated image frame extraction from video
to display all contents of the video in a 3D environment. This allows one to assess all time behaviors of a system at once, 
such as the cell division rate of a microscopy file.

## Installation:
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/4D-Pattern-Capture.git
2. Open the Xcode project file 4D Pattern Capture.xcodeproj
3. Build and run the project in Xcode.

## Usage:
1. Drag and drop a video file into the rectangular view.
2. Click and hold background, lighting and blend mode menus to adjust.
3. Use sliders to adjust image distance, transparency and contrast.
4. The time scale bar below the 3D object represents the timeline of the video.

## Best Practices:
1. Recommended videos are those with high contrast, and dark or light, preferably black or white, backgrounds, such as microscopy videos
or those taken at night.
2. Note: the contrast slider can only be adjusted BEFORE adding a video.
3. Recommended initial settings are a black or white background, constant lighting, and 'replace' blend mode.
4. Even when optimized with Metal, this is a GPU and memory intensive app. Therefore, consider starting with shorter videos under 100mb. 

## Contributing
	1.	Fork the repository.
	2.	Create a new branch (git checkout -b feature/your-feature).
	3.	Commit your changes (git commit -m 'Add some feature').
	4.	Push to the branch (git push origin feature/your-feature).
	5.	Open a Pull Request.

## License
This project is licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0). 
You are free to:
- Share: copy and redistribute the material in any medium or format
- Adapt: remix, transform, and build upon the material for any purpose, even commercially.
Under the following terms:
- **Attribution**: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in
any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
For more details, please refer to the [full license](https://creativecommons.org/licenses/by/4.0/).

![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)

## Credits
	•	Developed by Taylor Hinchliffe.
	•	Inspired by the intersection of art and science.

## Contact
For questions, please open an issue or contact tehinchliffe@gmail.com 
