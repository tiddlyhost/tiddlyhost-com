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

  $('.delete-confirm, .delete-cancel').on('click', function(event){
    $(this).closest('td').find('.delete-confirm, .delete-really, .delete-cancel').toggle();
    event.preventDefault();
  })

  // Make it so the user can't easily type invalid names.
  // We'll validate the name on the server as well, see app/models/site.
  $('#site_name').on('keyup', function(){
    $(this).val(
      $(this).val().
        // Remove anything that's not a letter, numeral or dash
        replace(/[^0-9a-z-]/, '').
        // Replace consecutive dashes with a single dash
        replace(/[-]{2,}/, '-').
        // Remove leading dashes
        // (Don't remove trailing dashes since it makes it hard to type
        // names with dashes. The server will invalidate them anyway.)
        replace(/^-/, '')
    );
  });

  // If site is set to private, automatically make it unsearchable
  // If site is set to searchable, automatically make it public
  $('#site_is_private'   ).on('change', function(){ if ($(this).prop('checked')) { $('#site_is_searchable').prop('checked', false); } });
  $('#site_is_searchable').on('change', function(){ if ($(this).prop('checked')) { $('#site_is_private'   ).prop('checked', false); } });

  // Initialize dataTable tables
  $('table.dataTable').DataTable();

});
