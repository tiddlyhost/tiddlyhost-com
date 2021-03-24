// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import * as ActiveStorage from "@rails/activestorage"

import "bootstrap"

import "datatables.net-dt"

Rails.start()
ActiveStorage.start()

$(document).ready(function(){

  var limitChars = function() {
    var inputField = $(this);

    if (inputField.attr('id') == 'site_name') {
      // Allow lowercase letters, numerals and dashes
      var notAllowed = /[^0-9a-z-]/;
    }
    else { // id == 'user_username"
      // Same thing but also allow uppercase
      var notAllowed = /[^0-9a-zA-Z-]/;
    }

    var currentVal = inputField.val();
    inputField.val(currentVal.
      // Remove any disallowed chars
      replace(notAllowed, '').
      // Replace consecutive dashes with a single dash
      replace(/[-]{2,}/, '-').
      // Remove leading dashes
      // (Don't remove trailing dashes since it makes it hard to type
      // names with dashes. The server will invalidate them anyway.)
      replace(/^-/, '')
    );
  };

  // Make it so the user can't easily type invalid site names or usernames.
  // We'll validate server-side as well, see User and Site model validations.
  $('form.new_site input#site_name').on('keyup', limitChars);
  $('form.edit_user input#user_username').on('keyup', limitChars);

  // If site is set to private, automatically make it unsearchable
  // If site is set to searchable, automatically make it public
  $('#site_is_private'   ).on('change', function(){ if ($(this).prop('checked')) { $('#site_is_searchable').prop('checked', false); } });
  $('#site_is_searchable').on('change', function(){ if ($(this).prop('checked')) { $('#site_is_private'   ).prop('checked', false); } });

  // Upload form UI tweaks
  $('#site_tiddlywiki_file').on('change', function(){
    var fileName = $(this).get(0).files.item(0).name;
    $('#upload-submit').prop('value', 'Upload file \"' + fileName + '\"').show();
  });

  // Initialize dataTable tables
  $('.dataTable').each(function(){

    // Choose default sort column
    var sortCol = 0;
    $(this).find('th').each(function(i){
      if ($(this).hasClass('default-sort')) { sortCol = i; }
    });

    $(this).dataTable({
      'order': [[sortCol, 'desc']],
      'pageLength': 10
    });
  });

});
