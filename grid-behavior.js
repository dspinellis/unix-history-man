/**
 * Functions required for customizing the SlickGrid behavior to
 * display Unix manual pages.
 *
 * Copyright 2017-2018 Diomidis Spinellis
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */

var data = [];
var uri = {};
var dataView;
var release_date = {};
var section;
var groupingDisabled = false;

// Filter out entries that are collapsed by their parents
function collapseFilter(item) {
  if (item.parent != null) {
    var parent = data[item.parent];
    while (parent) {
      if (parent._collapsed) {
	return false;
      }
      parent = data[parent.parent];
    }
  }
  return true;
}

// Remove parent nodes (*), pointers to them, and indentation
function disableGrouping() {
  if (groupingDisabled) {
    return;
  }
  for (var i = 0; i < data.length; i++) {
    if (data[i].Facility.slice(-1) == "*") {
      data.splice(i, 1);
      i--;
      continue;
    }
    data[i].indent = 0;
    data[i].parent = null;
  }
  groupingDisabled = true;
}

// Format the name of each facility, including its collapse icon
function FacilityNameFormatter (row, cell, value, columnDef, dataContext) {
  value = value.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
  var spacer = "<span style='display:inline-block;height:1px;width:" + (15 * dataContext["indent"]) + "px'></span>";
  var idx = dataView.getIdxById(dataContext.id);
  if (data[idx + 1] && data[idx + 1].indent > data[idx].indent) {
    if (dataContext._collapsed) {
      return spacer + " <span class='toggle expand'></span>&nbsp;" + value;
    } else {
      return spacer + " <span class='toggle collapse'></span>&nbsp;" + value;
    }
  } else {
    return spacer + " <span class='toggle'></span>&nbsp;" + value;
  }
}

// Format and hyperlink the timeline bars
function ImplementedFormatter(row, cell, value, columnDef, dataContext) {
  if (value == null || value === "")
    return "";
  var releaseId = columnDef.id;
  var release = uri[releaseId];
  var implemented = "<span class='implemented'></span>";
  if (!release)
    return implemented;
  var facility = dataContext.Facility;
  var target = release[facility];
  if (target)
    return "<a href='https://dspinellis.github.io/manview/" +
      "?src=" + encodeURIComponent("https://raw.githubusercontent.com/dspinellis/unix-history-repo/" + target) +
      "&name=" + encodeURIComponent(columnDef.name + ": " + facility + "(" + section + ")") +
      "&link=" + encodeURIComponent("https://github.com/dspinellis/unix-history-repo/blob/" + target) +
      "' target='_blank'><span class='linked'></span></a>";
  else
    return implemented;
}

// Order rows by the release dates
function gridSorter(cols, grid, gridData) {
  /*
   * After changing the order of the rows, the parent pointers are
   * no longer valid, so we disable grouping.
   */
  disableGrouping();
  gridData.sort(function (dataRow1, dataRow2) {
    for (var i = 0, l = cols.length; i < l; i++) {
      var field = cols[i].sortCol.field;
      var sign = cols[i].sortAsc ? 1 : -1;
      var value1 = dataRow1[field], value2 = dataRow2[field];
      if (field == "Appearance") {
	value1 = release_date[value1];
	value2 = release_date[value2];
      }
      var result = (value1 == value2) ?  0 :
	((value1 > value2 ? 1 : -1)) * sign;
      if (result != 0) {
	return result;
      }
    }
    return 0;
  });
  grid.invalidate();
  grid.render();
}
