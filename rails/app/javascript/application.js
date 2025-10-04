// Entry point for the build script in your package.json
// This file is automatically compiled by esbuild, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import * as ActiveStorage from "@rails/activestorage"
import $ from "jquery"
import * as bootstrap from "bootstrap"

// Make jQuery available globally
window.$ = window.jQuery = $

// Make Bootstrap available globally for the component initialization
window.bootstrap = bootstrap

// Add Bootstrap jQuery plugin compatibility layer
// This allows legacy code to use $(...).modal(), $(...).popover(),
// and $(...).tooltip().
$.fn.modal = function(action) {
  return this.each(function() {
    const modalInstance = bootstrap.Modal.getOrCreateInstance(this);
    if (action === 'show') {
      modalInstance.show();
    } else if (action === 'hide') {
      modalInstance.hide();
    } else if (action === 'toggle') {
      modalInstance.toggle();
    } else if (typeof action === 'object' || !action) {
      // Initialize with options or just initialize
      return modalInstance;
    }
  });
};

$.fn.popover = function(options) {
  return this.each(function() {
    new bootstrap.Popover(this, options);
  });
};

$.fn.tooltip = function(options) {
  return this.each(function() {
    new bootstrap.Tooltip(this, options);
  });
};

Rails.start()
ActiveStorage.start()

window.setLightDark = function () {
  const html = document.documentElement;

  // Set by the server based on a cookie or user preference
  // Could be "light", "dark", "auto"
  const wanted = html.getAttribute('data-theme-mode');

  // From the user's browser settings
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

  var useTheme;
  if (wanted == "dark" || (wanted != "light" && prefersDark))
    useTheme = "dark";
  else
    useTheme = "light";

  // This is what bootstrap (and our own styles) pay attention to
  // Should be "light" or "dark", but not "auto"
  html.setAttribute('data-bs-theme', useTheme);
}

// We want this to happen before the page is rendered to avoid a potential
// FOUC, so that's why it's here and not in $(document).ready(...)
setLightDark();

$(document).ready(function () {

  var limitChars = function () {
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
  $('.private-checkbox').on('change', function () { if ($(this).prop('checked')) { $('.hub-checkbox').prop('checked', false); } });
  $('.hub-checkbox').on('change', function () { if ($(this).prop('checked')) { $('.private-checkbox').prop('checked', false); } });

  // Same thing for libravatar/gravatar
  $('#user_use_gravatar').on('change', function () { if ($(this).prop('checked')) { $('#user_use_libravatar').prop('checked', false); } });
  $('#user_use_libravatar').on('change', function () { if ($(this).prop('checked')) { $('#user_use_gravatar').prop('checked', false); } });

  // Upload form UI tweaks
  $('#site_tiddlywiki_file').on('change', function () {
    var fileName = $(this).get(0).files.item(0).name;
    $('#upload-submit').prop('value', 'Upload file \"' + fileName + '\"').show();
  });

  // Trick to set cursor position to the end of the text in the search box
  $("#search_box").each(function () {
    var search_box = $(this);
    var orig_text = search_box.val();
    search_box.val('');
    search_box.val(orig_text);
  })

  // Highlight the selected radio button by adding the selected class to
  // its parent div and removing it from the other options' parent divs.
  // See also _nice_radio.scss.
  //
  $('.nice-radio-container input:radio').on('click', function () {
    $(this).closest('.nice-radio-container').find('> div').removeClass('selected');
    $(this).closest('div').addClass('selected');
  });

  // For the "More options" link when creating a site.
  // See also the type_chooser scss and partial.
  //
  $('.longer-link').on('click', function (e) {
    $('.type-chooser').toggleClass('longer');
    e.preventDefault();
  });

  // For the access choice radio buttons on the site form.
  // Set the hidden "real" boolean fields based on which one is clicked.
  // We're expecting one of "public", "private" and "hub_listed".
  //
  $('input:radio[name="_access_choice"]').on('change', function () {
    var choice = $(this).val();
    $("input#site_is_private, input#tspot_site_is_private").val(choice == "private");
    $("input#site_is_searchable, input#tspot_site_is_searchable").val(choice == "hub_listed");
  });

  // Enable boostrap popovers and tooltips
  //
  $('.enable-tooltips a[data-bs-toggle="popover"]').
    on('click', function (e) { e.preventDefault(); }).
    popover({ "trigger": "focus", "html": true });

  $('.enable-tooltips a[data-bs-toggle="tooltip"]').tooltip();

  // For show/hide password visibility
  $('.passwd-btn').on('click', function (e) {
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

  // Three-way theme cycling: auto -> light -> dark -> auto ...
  // See also mode_cycle in the HomeController which does the same
  // thing server side to persist it in a cookie and a user preference
  // if the user is logged in
  $('.mode-cycle-btn').on('click', function (e) {
    var currentMode = document.documentElement.getAttribute('data-theme-mode') || 'auto';
    var nextMode;

    // Todo maybe: Use same algorithm as lib/cycle_helper
    if (currentMode === 'light')
      nextMode = 'dark';
    else if (currentMode === 'dark')
      nextMode = 'auto';
    else
      nextMode = 'light';

    document.documentElement.setAttribute('data-theme-mode', nextMode);
    setLightDark();
  });

  // Activate crawler-protected links after page load.
  // The goal is to stop crawlers from endlessly following
  // tag/user/sort/filter links.
  $('a[data-crawler-protect-href]').each(function() {
    var link = $(this);
    var realHref = link.attr('data-crawler-protect-href');
    link.attr('href', realHref);
    link.removeAttr('data-crawler-protect-href');
  });
});
