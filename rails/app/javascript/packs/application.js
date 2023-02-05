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

  // The name field is autofocussed on site creation.
  // Also make it selected since it will be a randomly generated
  // site name the user will probably want to replace.
  $('input#site_name[autofocus="autofocus"]').select();

  // If user checks 'private', automatically uncheck 'hub listed'
  // If user checks 'hub listed', automatically uncheck 'private'
  $('.private-checkbox').on('change', function(){ if ($(this).prop('checked')) { $('.hub-checkbox'    ).prop('checked', false); } });
  $('.hub-checkbox'    ).on('change', function(){ if ($(this).prop('checked')) { $('.private-checkbox').prop('checked', false); } });

  // Upload form UI tweaks
  $('#site_tiddlywiki_file').on('change', function(){
    var fileName = $(this).get(0).files.item(0).name;
    $('#upload-submit').prop('value', 'Upload file \"' + fileName + '\"').show();
  });

  // Trick to set cursor position to the end of the text in the search box
  $("#search_box").each(function(){
    var search_box = $(this);
    var orig_text = search_box.val();
    search_box.val('');
    search_box.val(orig_text);
  })

  // Highlight the selected radio button by adding the selected class to
  // its parent div and removing it from the other options' parent divs.
  // See also _nice_radio.scss.
  //
  $('.nice-radio-container input:radio').on('click', function(){
    $(this).closest('.nice-radio-container').find('> div').removeClass('selected');
    $(this).closest('div').addClass('selected');
  });

  // For the "More options" link when creating a site.
  // See also the type_chooser scss and partial.
  //
  $('.longer-link').on('click', function(e){
    $('.type-chooser').toggleClass('longer');
    e.preventDefault();
  });

  // For the access choice radio buttons on the site form.
  // Set the hidden "real" boolean fields based on which one is clicked.
  // We're expecting one of "public", "private" and "hub_listed".
  //
  $('input:radio[name="_access_choice"]').on('change', function(){
    var choice = $(this).val();
    $("input#site_is_private, input#tspot_site_is_private").val(choice == "private");
    $("input#site_is_searchable, input#tspot_site_is_searchable").val(choice == "hub_listed");
  });

  // Enable boostrap popovers and tooltips
  //
  $('.enable-tooltips a[data-bs-toggle="popover"]').
    on('click', function(e){ e.preventDefault(); }).
    popover({ "trigger":"focus", "html":true });

  $('.enable-tooltips a[data-bs-toggle="tooltip"]').tooltip();

  // For show/hide password visibility
  $('.passwd-btn').on('click', function(e){
    var inputGroup = $(this).closest('.input-group');
    var passwdInput = inputGroup.find('input')

    if (passwdInput.attr('type') == 'password') {
      // Currently hidden, make it visible
      passwdInput.attr('type', 'text');
    }
    else {
      // Currently visible, make it hidden
      passwdInput.attr('type', 'password');
    }

    // Switch the two button icons
    inputGroup.find('.passwd-btn-icon').toggle()

    // Save the user a click
    passwdInput.focus();

    // Not sure if this is needed here, but probably
    // harmless either way
    e.preventDefault();
  });

  $('.mode-toggle-btn').on('click', function(e){
    var currentTheme = $('html').attr('data-bs-theme');
    var newTheme = currentTheme == "dark" ? "light" : "dark";
    $('html').attr('data-bs-theme', newTheme)
  });

  const setTheme = function (theme) {
    if (theme === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      document.documentElement.setAttribute('data-bs-theme', 'dark')
    } else {
      document.documentElement.setAttribute('data-bs-theme', theme)
    }
  }

});
