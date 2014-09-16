#!/bin/bash
# coffee -cw -o ../ timeslotBrowser.coffee
coffee -o ../ -j timeslotBrowser_0_1b.js -cw controller.coffee model.coffee view.coffee dateUtils.coffee
