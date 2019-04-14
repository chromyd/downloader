# Freestream

Freestream downloads all HTTP stream files for a specified M3U playlist.

## Prerequisites
### Dependencies
```
brew install ffmpeg
brew install tesseract --HEAD
```
### Browser Plug-ins
#### Enable CORS
CORS needs to be enabled for Freestream to work with certain streaming providers. Because it cannot
be enabled server-side for obvious reasons, a browser plug-in is required.

Recommended plug-in:
- https://chrome.google.com/webstore/detail/resource-override/pkoacgokdfckfpndoffpifphamojphii

Plug-in Configuration:
- https://github.com/chromyd/freestream/blob/master/resource_override_rules.json

#### Disable Download Bar
The sheer number of downloads is annoying when download bar is enabled. This plugin remedies this:
- https://chrome.google.com/webstore/detail/disable-download-bar/epnnapjdpplekmodajomjojfpeicclep
