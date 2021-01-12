// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import * as ActiveStorage from "@rails/activestorage"

import "bootstrap"

Rails.start()
ActiveStorage.start()

$(document).ready(function(){

  $('.delete-confirm, .delete-cancel').on('click', function(event){
    $(this).closest('td').find('.delete-confirm, .delete-really, .delete-cancel').toggle();
    event.preventDefault();
  })

  // We'll validate this on the server, this is just for the UI
  $('.site-name').on('keyup', function(){
    $(this).val(
      $(this).val().
        // Only letters or - chars
        replace(/[^0-9a-z-]/, '').
        // No consecutive - chars
        replace(/[\-]{2,}/, '-').
        // Must start with letter or number
        replace(/^-/, '').
        // Must end with letter or number
        replace(/-$/, '').
        // 63 char limit
        substring(0, 63));
  });

});
