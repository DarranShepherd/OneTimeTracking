# One Time Tracking

_A Google Chrome plugin for managing Harvest timers and sync them with Target Process projects_

## Summary

Hayfever is a plugin for Google Chrome that lets you manage your [Harvest](http://www.getharvest.com) timers and timesheets.

One Time Tracking is built on top of the Hayfever extension to log time to Target Process in addition to Harvest.

### Stuff OneTimeTracking Can Do

OneTimeTracking can currently:

* Authenticate w/ Harvest time tracking API
* Authenticate w/ Target Process API
* Display a badge with total hours worked today
* Display a list of existing timers
* Start and stop existing timers
* Create new timers for Harvest
* Create new timers for Harvest that are linked with Target Process projects
* Edit and update existing timers


### The Hacker Method

If you're *REALLY* the DIY type, you can clone this repo and install it ninja-style. You'll need to run a few commands to compile CSS, CoffeeScript, and package the extension as a zip file. You must have CoffeeScript and Bower installed and in your `PATH`.

```
# Install CoffeeScript and Bower if necessary:
$ npm install -g coffee-script bower

# Install dependencies and compile CSS + CoffeeScripts:
$ bundle install
$ bower install
$ thor project:build

# There's also a thor task for packaging the extension as a zip file inside the pkg/ folder:
$ thor project:zip_release
```

From there you can install the extension by enabling developer mode in chrome://extensions and loadng the `build` directory as an unpacked extension.

## Usage Statistics

OneTimeTracking gathers usage statistics via Google Analytics, but only if you decide to let it. Right now it do __not__ do any event tracking, so the only data it get is how many people use the plugin and how often.

Analytics are turned off by default because I believe it should be a matter of choice.

## License

This extension is released according to the terms of the GNU General Public License, version 2. See [LICENSE](https://github.com/lmanapure/OneTimeTracking/blob/master/LICENSE) for details.

[1]: http://www.pledgie.com/campaigns/14742
[2]: http://www.pledgie.com/campaigns/14742.png?skin_name=chrome
