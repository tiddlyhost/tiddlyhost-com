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

  $('table.dataTable').DataTable();

});
