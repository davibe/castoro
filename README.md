Description
-----------

A commandline tool to cast local files to chromecast.


Install
-------

    npm install -g coffee-script
    cd [this repo]
    npm install -g


Usage
-----

Command line usage goes like this

      castoro \
        --ip [ip of your machine] \
        --mode [original|stream-transcode|transcode] \
        --input [path/to/file.mkv]

Optional arguments

        --port [http port to use]
        --cli-controller # enables cli controller


### Mode(s)


#### "original"

The tool will stream un-modified input file using HTTP. Since chromecast is
picky about formats (expecially audio ones) the file must be properly encoded.

#### "stream-transcode"

The tool will live transcode the input file to fit chromecast audio capabilities
using ffmpeg. At the moment this disables seeking support.

#### "transcode"

The tool will

1. start to cast the input media to the chromecast using stream-transcode mode
   (no seeking enabled)
2. start a transcoding process converts the entire input media
3. as soon as the transcoding (2) is finished it will switch playback to the
   trascoded file (seeking will be re-enabled)


### Cli controller

Use keys to control playback/volume

- Up: Volume up
- Down: Volume down
- Left: RR
- Right: FF
- Space: Pause/Unpause
- key "s": Print player status
- key "q": Quit


Todos
-----

Pull requests are welcome

- Make pause/unpause more stable
- Figure out how to do seeking in 'stream-transcode' mode to make 'transcode'
  useless
- Also transcode video when needed (currently we just transcode audio)
- Automatically figure out available port
- Automatically figure out appropriate ip
- Support multiple chromecasts in the same network
- Maybe create a user interface served with express 
