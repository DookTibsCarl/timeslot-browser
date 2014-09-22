#!/bin/bash
# coffee -cw -o ../ timeslotBrowser.coffee
# coffee -o ../ -j timeslotBrowser_0_1b.js -cw controller.coffee model.coffee view.coffee dateUtils.coffee
coffee -o ../ -j timeslotBrowser_0_1b.js -c controller.coffee model.coffee view.coffee dateUtils.coffee
cp ../timeslotBrowser_0_1b.js /Users/tfeiler/remotes/ventnorTfeilerReason/global_stock/timeslotBrowser/timeslotBrowser.js
cp ../grid.css /Users/tfeiler/remotes/ventnorTfeilerReason/global_stock/timeslotBrowser/timeslotBrowser.css
