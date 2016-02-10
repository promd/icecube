// list data array for filling in info box
var ListData = [];

// DOM Ready =============================================================
$(document).ready(function() {

    // Populate the table on initial page load
    populateTable();
    var socket = io();
});

// Functions =============================================================

// Fill table with data
function populateTable() {

    // Empty content string
    var tableContent = '';

    // jQuery AJAX call for JSON
    $.getJSON( '/rooms', function( data ) {

        // For each item in our JSON, add a table row and cells to the content string
        $.each(data, function(){
            tableContent += '<tr>';
            tableContent += '<td><a href="#" class="linkshowuser" rel="' + this.name + '">' + this.name + '</a></td>';
            tableContent += '<td>' + this.alias + '</td>';
            tableContent += '<td>' + this.capacity + '</td>';
            tableContent += '<td><a href="#" class="linkdeleteuser" rel="' + this["@rid"] + '">block</a></td>';
            tableContent += '</tr>';
        });

        // Inject the whole content string into our existing HTML table
        $('#userList table tbody').html(tableContent);
    });
};
