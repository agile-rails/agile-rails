/*
# Copyright (c) 2024+ Damjan Rems
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

  mouseDown = false;

/*******************************************************************
 * Find and extract parameters value from url
 *******************************************************************/
$.getUrlParam = function(name) {
  var results = new RegExp('[\\?&]' + name + '=([^&#]*)').exec(window.location.href);
  if (results == null) return null;
  return results[1] || 0;
};

/*******************************************************************
 * Dump all attributes to console
 *******************************************************************/
dumpAttributes = function(obj) {
  console.log('Dumping attributes:');
  $.each(obj.attributes, function() {
    console.log(this.name,this.value);
  });
};

/*******************************************************************
 * Function checks if there are delay loaded embedded elements on 
 * selected tab and triggers iframe reload.
 *******************************************************************/
update_embedded_on_tab_select = function(div_name) {
  let iframes = $(div_name).find("iframe");
  $.each(iframes, function(index, iframe) {
    // delayed load
    let src_delay = iframe.getAttribute('data-src-delay');
    if (src_delay != null && src_delay != '') {
      iframe.setAttribute('data-src-delay', '');
      iframe.setAttribute('src', src_delay);
    }
    // always load on tab select
    let src_always = iframe.getAttribute('data-src-always');
    if (src_always != null) {
      iframe.setAttribute('src', src_always);
    }
    // resize iframe to it's scroll height
    let iframe_height= iframe.contentWindow.document.documentElement.scrollHeight;
    iframe.style.height = iframe_height.toString() + 'px';
  });
};

/*******************************************************************
 *  Return false when confirmation is not required 
 *******************************************************************/
confirmation_is_cancelled = function(object) {
  let confirmation = '';
  if ($.type(object) === "string") {
    confirmation = object;
  } else {
    confirmation = object.getAttribute("data-confirm");
  }
  // if confirmation required
  if (confirmation !== null) {
    if (!confirm(confirmation)) {return true;}
  }
  return false;
};

/*******************************************************************
 * Will update select field on the form which select options are depend
 * on other field value. It calls /agile_common/autocomplete and passes
 * method name and depend field value to obtain new values for select field.
 *******************************************************************/
update_select_depend = function(select_name, depend_name, method) {
  let select_field = $('#' + select_name);
  let depend_value= '';
  let depend_field= null;
  let field_value= null;

  depend_name.split(",").forEach( function(depend) {
    if ( $('#record_' + depend.trim()).length ) {
      depend_field = $('#record_' + depend.trim());
    } else {
      depend_field = $('#_record_' + depend.trim()); // virtual field
    }

    // checkbox
    if (depend_field.is(':checkbox'))  {
      field_value = depend_field.is(":checked");
    } else {
      field_value = depend_field.val();
    }

    if (depend_value.length > 0) depend_value = depend_value + ',';
    depend_value = depend_value + field_value;
  });

  $.ajax({
    url: "/agile/autocomplete",
    type: "POST",
    dataType: "json",
    data: { input: depend_value, search: method},
    success: function(data) {

      select_field.empty();
      $.each(data, function(index, element) {
        select_field.append( new Option(element['label'], element['id']) );
      });
      // refresh multiple select field
      if (select_field.hasClass('select-multiple')) { select_field.selectMultiple('refresh') }
    }
  });
};

/*******************************************************************
 * Format number input field according to data
 *******************************************************************/
format_number_field = function(e) {
  let decimals  = e.attr("data-decimal") || 2;
  let delimiter = e.attr("data-delimiter") || '.';
  let separator = e.attr("data-separator") || ',';
  let currency  = e.attr("data-currency") || '';
  let whole = e.val().split(separator)[0];
  let dec   = e.val().split(separator)[1];
// save value to hidden field which will be used for return 
  let field = '#' + e.attr("id").slice(0,-1);
  let value = e.val().replace(delimiter,'.');

  $(field).val( parseFloat(value).toFixed(decimals) );

// decimal part
  if (dec == null) dec = '';
  dec = dec.substring(0, decimals, dec);
  while (dec.length < decimals) dec = dec + '0';
// whole part 
  if (whole == null || whole == '') whole = '0';
  let ar = [];

  while (whole.length > 0) {
    let pos1 = whole.length - 3
    if (pos1 < 0) pos1 = 0;
    ar.unshift(whole.substr(pos1,3)); 
    whole = whole.slice(0, -3); 
  };

  if (delimiter !== '') whole = ar.join(delimiter);
  e.val(whole + separator + dec + currency);
};

/*******************************************************************
 * Dynamically loads javascript file from filesystem
 *******************************************************************/
function load_script( url, callback ) {
  let script = document.createElement( "script" )
  script.type = "text/javascript";
  script.src = url;
  script.onload = function() {
    callback()
  };
  document.head.appendChild(script);
}

/*******************************************************************
 * Activate jquery UI tooltip. This needs jquery.ui >= 1.9
 *******************************************************************/
/*
$(function() {
  $( document ).tooltip();
});
*/

/*******************************************************************
 * Process json result from ajax call and update parts of document.
 *
 * Protocol consists of operation and value which are returned as json by
 * called control method. Control method will return a json result usually like this:
 *    render json: { operation: value }
 *    
 * Operation is further divided into source and selector which are divided by underline char.
 *    render json: { #div_status: 'OK!' }
 * will replace html in div="status" with value 'OK!'. Source is '#div' selector is 'status'.
 * 
 * Possible combinations are:
 *
 * #div_divname : will replace divname with value
 * #div+_divname : will append value to divname
 * #+div_divname : will prepend value to divname
 * .div_classname : will replace all occurrences of classname with value
 * .+div_classname : will prepend value to all occurrences of classname
 * .div+_classname : will append value to all occurrences of classname
 *
 *  Other options:
 *
 *  record_name: will replace value of record[name] field on a form with supplied value
 *
 *  msg_error: will display error message
 *  msg_warning: will display warning message
 *  msg_info: will display informational message
 *  popup: will display popup message
 *  alert: will display standard alert message
 *
 *  url: url - will force loading of url supplied in value into same window
 *  parenturl: url - will force loading of url supplied in value into parent frame
 *  window: url - will force loading of url supplied in value into window on a new tab
 *  newwindow: url - will force loading of url supplied in value into new windowed dialog
 *  reload: true - will reload current frame
 *  reload: parent - will reload parent frame
 *
 *  script: Will evaluate provided javascript.
 *
 *  Operations can be chained and are executed sequential.
 *    render json: {window: "/document.pdf", reload: true }
 *  will open /document.pdf in new window and reload current window.
 *  
 *    render json: {'record_name' => "Damjan", 'record_surname' => 'Rems'}
 *  will replace values of two fields on the form.
 *******************************************************************/

process_json_result = function(json) {
  let i, w, operation, selector, msg_div, field;
  $.each(json, function(key, value) {
    i = key.search('_');
    if (i > 1) {
      operation = key.substring(0, i);
      selector  = key.substring(i+1, 100);
    } else {
      operation = key;
      selector  = '';
    }

    switch (operation) {
      
/**** update fields on form ****/
    case 'record':
      //let name = key.replace('record_','record[') + ']';
      //field = $('[name="' + name + '"]');
      field = $('#' + key);
      // console.log(field);
      // checkbox field
      if (field.is(':checkbox')) {
        field.prop('checked', value);
      // select field  
      } else if (field.is('select')) {
        // options for select field
        if (Array.isArray(value)) {
          field.empty();
          $.each(value, function(index, v) {
            field.append( new Option(v[0], v[1]) );
          });
        // select field value
        } else {
          field.val(value).change();
        }
      // radio field
      } else if (field.attr('type') == 'radio') {
        field.val([value])

      // other input fields
      } else {
        field.val(value);
      }
      break;

/**** transfer focus to field ****/
    case 'focus':
      $('#' + value).focus();
      break;

/**** display message ****/
    case 'msg': 
      let msg_div = 'ar-form-' + selector;
      if ( $('.' + msg_div).length == 0 ) {
        value = '<div class="' + msg_div + '">' + value + '</div>';
        $('.ar-title').after(value);
      } else {
        $('.' + msg_div).html(value);
        $('.' + msg_div).show();
      }
      break;
      
/**** display popup message ****/
      case 'popup':
        if (selector === 'url') {
          $('#popup').bPopup({ loadUrl: value,
            transition: 'slideDown', transitionClose: 'slideDown', speed: 300,
            opacity: 0, position: ['auto', 20],
            closeClass: 'ar-link' });
        }
        else {
          if (selector === '') { selector = 'info' }
          let popup_html = '<div class="popup-' + selector + '">' + value + '<br><button class="ar-link">OK</button></div>';
          $('#popup').html(popup_html);
          $('#popup').bPopup( {
            transition: 'slideDown', transitionClose: 'slideDown', speed: 300,
            opacity: 0, position: ['auto', 150],
            closeClass: 'ar-link' });
        }
        // resize parent iframe if smaller then 500px to ensure popup some space
        let document_height = document.body.scrollHeight;
        if (document_height < 500) {
          let frame = window.frameElement
          if (frame === null) frame = document.body;
          frame.style.height = '500px';
        }
        break;

/**** update div ****/
    case '#div+':
      $('#'+selector).append(value);
      break;
    case '#+div':
      $('#'+selector).prepend(value);
      break;
    case '#div':
      $('#'+selector).html(value);
      break;
    case '.div+':
      $('.'+selector).append(value);
      break;
    case '.+div':
      $('.'+selector).prepend(value);
      break;
    case '.div':
      $('.'+selector).html(value);
      break;
      
/**** goto url ****/
    case 'url':
      window.location.href = value;
      break;
    case 'parenturl':
      parent.location.href = value;
      break;
    case 'iframeurl':
        let [iframe, url] = value.split(";");
         document.getElementById(iframe).src = url
        break;
    case 'alert':
      alert(value);
      break;
    case 'window':
      if (value == 'close') { window.close(); 
      } else if (value == 'reload') {
        window.location.href = window.location.href;
      } else {
        w = window.open(value, selector);
        w.focus();
      }
      break;
    case 'newwindow':
      w = window.open(value, selector,"location=no,scrollbars=yes,resizable=yes");
      w.focus();        
      break;
    case 'script':
      eval (value);
      break; 
    case 'reload':
      value = value.toString();
      if (value == 'parent') {
        //parent.location.reload();
        parent.location.href = parent.location.href;

/*** this would be current window (reload: true) ****/
      } else if (value.length < 5) {
        window.location.href = window.location.href;
/*** reload iframe ****/
      } else {
        $( '#' + value ).attr('src', $( '#' + value ).attr('src'));
      } 
      break;
    default: 
      console.log("AgileRails: Invalid ajax result operation: " + operation);
    }
  });
};

/*******************************************************************
 * Will reload window
 *******************************************************************/
function agile_reload_window() {
  location.reload(); 
}

/*******************************************************************
 * Will open popup window
 *******************************************************************/
function popup_window(url, title, parent_win, w, h) {
  let y = parent_win.top.outerHeight / 2 + parent_win.top.screenY - (h / 2);
  let x = parent_win.top.outerWidth / 2 + parent_win.top.screenX - (w / 2);
  let win = parent_win.open(url, 'agile_popup', `toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=no, resizable=no, copyhistory=no, width=${w}, height=${h}, top=${y}, left=${x}`);
  win.document.title = title;
  return win;
}

/*******************************************************************
 * Will select first editable input field on form. Works only when tab
 * is selected. Still have to find out, what to do on initial display.
 *******************************************************************/
function select_first_input_field(div_name) {
  $(div_name + " :input:first").each( function() {
    this.focus();
    return true;
  });
}

/*******************************************************************
 * Will scroll to position on the screen. This is replacement for 
 * location.hash, which doesn't work in Chrome.
 * 
 * Thanks goes to: http://web-design-weekly.com/snippets/scroll-to-position-with-jquery/
 *******************************************************************/
$.fn.agile_scroll_view = function () { 
  return this.each(function () {
    $('html, body').animate({
      scrollTop: $(this).offset().top - 100
    }, 500);
  });
};

/*******************************************************************
 * Updates single field on parent iframe form of embedded form.
 *******************************************************************/
process_parent_form_updates = function(element) {
  let field = element.getAttribute("data-field");
  let value = element.getAttribute("data-value");
  let selector = '#' + field;

  // update record
  if (field.match(/record/)) {
    if (window.parent.$(selector).length > 0) {
      if (field.substring(0, 3) === 'td_') {   // readonly field
        window.parent.$(selector + ' > div').html(value);
      } else { // input field
        window.parent.$(selector).val(value);
      }
    }
  // any div
  } else {
    if (window.parent.$(selector).length > 0) {
      window.parent.$(selector).html(value);
    }
  }
};

/*****************************************************************
 * Toggle show and hide div
 ******************************************************************/
agile_div_toggle = function(div) {
  if ($(div).is(":visible")) {
    $(div).slideUp();
  } else {
    $(div).slideDown();
  }
};

/*****************************************************************
 * Process simple ajax call
 ******************************************************************/
simple_ajax_call = function(url) {
  $.ajax({
    url: url,
    success: function(data) { process_json_result(data); }
  });
};

/*****************************************************************
 * Return value of the input field on a form
 ******************************************************************/
function agile_field_get_value(field_name) {
  field_name = field_name.replace('record_', '');
  let field = $('[name="record[' + field_name + ']"]');
  return field.val();
}

/*****************************************************************
 * Will process data-fields attribute and add field values as parameters to url
 ******************************************************************/
function agile_url_add_params(form, url) {
  // check if data-fields attribute present
  let fields = form.getAttribute("data-fields");
  if (fields === null) return url;
  // url might already contain ?
  let form_parms = '?';
  if (url.match(/\?/)) form_parms = '';

  fields.split(',').forEach( function(field) {
    let value = agile_field_get_value(field);
    if (value) form_parms += '&' + field + '=' + value;
  });
  return url + form_parms;
}

/*******************************************************************
 * Copy div text to clipboard
 *******************************************************************/
function agile_copy_to_clipboard(div) {
  let copyText = document.getElementById(div).innerText;
  // Copy the text inside the text field
  navigator.clipboard.writeText(copyText);
}

/*
function handleIframeBlurred(iframe) {
  console.log('iframe blurred');
  jQuery('#agile_form').submit();
  // Additional logic that you need to implement here when blurred
}
*/
/*
function handleIframeBlurred(){
  console.log('iframe blurred');
  // Additional logic that you need to implement here when blurred
}

function handleIframeFocus(){
  console.log('iframe focus');
  // Additional logic that you need to implement here when blurred
}

var active_iframe = null;
 */
let timeoutId = null;

/*******************************************************************
 * Events start here
 *******************************************************************/
$(document).ready( function() {
/* This could be the way to focus on first input field on document open
  if ( $('.ar-form')[0] ) {
// resize parent iframe to fit selected tab size
    var div_height = $('.ar-form')[0].clientHeight + 130;
    window.frameElement.style.height = div_height.toString() + 'px';
//    select_first_input_field('.ar-form');
  }
*/
  /*
    $('#if_#{@yaml['name']}').addEventListener('blur', handleIframeBlurred);
  $('#if_#{@yaml['name']}').addEventListener('focus', handleIframeFocus);

  console.log(jQuery(".iframe_embedded").length);
  console.log(window.frameElement);
   */
  /*******************************************************************
  * It will scroll display to ypos if return_to_ypos parameter is present
  *******************************************************************/
  if (window.location.href.match(/return_to_ypos=/))
  {
    window.scrollTo(0, $.getUrlParam('return_to_ypos'));
  }
  
 /*******************************************************************
  * The idea is to update fields on parent iframe form, when embedded document
  * is updated in its iframe. Update fields are listed in .ar-form-updates div
  * and are set by flash[:update] Hash object.
  * 
  * eg. flash[:update] = {'td_record_radonly' => 'New value for read_only field',
  *                       'record_name' => 'New name'}
  *******************************************************************/
  if ( $('.ar-form-updates').length > 0 ) {
     $('.ar-form-updates').children().each( function( index, element ) {
       process_parent_form_updates(element);
     });
  }
  
 /*******************************************************************
  * Register ad clicks
  *******************************************************************/
  $('a.link_to_track').click(function() {
    $.post('/agile/ad_click', { id: this.id });
    return true;
  });
  
 /*****************************************************************
 * Toggle CMS mode. When clicked on left 30 pixels, window will be scrolled approximately 
 * to the position wher toggle was clicked. When clicked from pixel 31 and on it will
 * stay on the top of window.
 ******************************************************************/  
  $('.cms-toggle').bind('click', function(e) {
    var url = '/agile/toggle_edit_mode?return_to=' + window.location.href;
    if (e.pageX < 30) url = url + '&return_to_ypos=' + e.pageY ;
    window.location.href = url;
  });
 
 /*******************************************************************
  * Popup or close CMS edit menu on icon click
  *******************************************************************/
  $('.ar_popmenu').on('click',function(e) { 
    $(e.target).parents('dl:first').find('ul').toggleClass('div-hidden'); 
  });

  /*******************************************************************
  * Popup CMS edit menu option clicked
  *******************************************************************/
  $('.ar_popmenu_item').on('click',function(e) {
    let url = e.target.getAttribute("data-url");
    $('#iframe_cms').attr('src', url);
//    $('#iframe_cms').width(1000).height(1000);
// scroll to top of page and hide menu    
    window.scrollTo(0,0);
    $(e.target).parents('dl:first').find('ul').toggleClass('div-hidden');
  });

 /*******************************************************************
  * Sort action clicked on browser
  *******************************************************************/
  $('.ar-sort-select').change( function(e) {
    let table = e.target.getAttribute("data-table");
    let form  = e.target.getAttribute("data-form");
    if (form === null) form = table;
    let sort = e.target.value;
//    e.target.value = null;
    let url = "/agile/run?control=agile.sort&sort=" + sort + "&table=" + table +  "&form_name=" + form;
    simple_ajax_call(url);
  });

  /*******************************************************************
   * Click on field name in result header perform sort action
   *******************************************************************/
  $('.ar-result-header span').on('click',function(e) {
    let url = e.target.getAttribute("data-url");
    simple_ajax_call(url);
  });

  /*******************************************************************
   * Click on ar-check-all icon. Check or uncheck all checkboxes
   *******************************************************************/
  $('.ar-check-all').on('click',function(e) {
    let checkboxes = $('.ar-check');
    if ($(this).hasClass('mi-check_box')) {
      // check all checkboxes
      checkboxes.each( function() {
        $(this).prop('checked', true);
        $(this).parent().closest('div').addClass('ar-checked');
      });
      $(this).removeClass('mi-check_box').addClass('mi-check_square');
    } else {
      // uncheck all checkboxes
      checkboxes.each( function() {
        $(this).prop('checked', false);
        $(this).parent().closest('div').removeClass('ar-checked');
      });
      $(this).removeClass('mi-check_square').addClass('mi-check_box');
    }
  });

  /*******************************************************************
   * Click on ar-check icon. Change color of background of element
   *******************************************************************/
  $('.ar-check').on('click',function(e) {
    let parent = $(this).parent().closest('div');
    if ($(this).prop('checked')) {
      parent.addClass('ar-checked');
    } else {
      parent.removeClass('ar-checked');
    }
  });

 /*******************************************************************
  * Tab clicked on form. Hide old and show selected div.
  *******************************************************************/
  $('.ar-form-li').on('click', function(e) { 
    // find li with ar-form-li-selected class. This is our old tab
    let old_tab_id = null;
    $(e.target).parents('ul').find('li').each( function() {
      if ($(this).hasClass('ar-form-li-selected')) {
        // when not already selected toggle ar-form-li-selected class and save old tab
        if ($(this) !== $(e.target)) {
          $(this).toggleClass('ar-form-li-selected');
          $(e.target).toggleClass('ar-form-li-selected');
          old_tab_id = this.getAttribute("data-div");
        }
        return false;
      }
        
    }); // show selected data div 
    if (old_tab_id !== null) {
      $('#data_' + old_tab_id).toggleClass('div-hidden');
      $('#data_' + e.target.getAttribute("data-div")).toggleClass('div-hidden');
      
      // resize parent iframe to fit selected tab size
      let div_height = document.body.scrollHeight;
      let frame = window.frameElement
      if (frame === null) frame = document.body;
      frame.style.height = div_height.toString() + 'px';

      select_first_input_field('#data_' + e.target.getAttribute("data-div"));
      update_embedded_on_tab_select('#data_' + e.target.getAttribute("data-div"));
    }
  });

  /*******************************************************************
   ******************************************************************/
  $('.xar-form-accordion').on('click', function(e) {
    $(this).toggleClass('open');
    $('#tab-' + e.target.id).toggleClass('div-hidden');
    if ($('#tab-' + e.target.id).is(':visible')) {
      select_first_input_field('#tab-' + e.target.id);
    }
  });
  /*******************************************************************
   ******************************************************************/
  $('.ar-form-accordion').on('click', function(e) {
    $(this).toggleClass('open');
    let data_div = '#' + e.target.id.replace('acc_', 'data_');
    $(data_div).toggleClass('div-hidden');
    if ($(data_div).is(':visible')) {
      select_first_input_field(data_div);
      update_embedded_on_tab_select(data_div);
    }
  });

  /*******************************************************************
   * refresh (reload) button clicked
   *******************************************************************/
  $('.ar-link.refresh').on('click', function(e) {
    window.location.href = window.location.href;
  });

  /*******************************************************************
   * close window
   *******************************************************************/
  $('.ar-link.close').on('click', function(e) {
    window.close();
  });

  /*******************************************************************
   * History back
   *******************************************************************/
  $('.ar-link.back').on('click', function(e) {
    history.back();
  });


/*******************************************************************
 * Resize iframe_cms to the size of its contents. Make at least 500 px high
 * unless on initial display.
 *******************************************************************/
  $('#iframe_cms').on('load', function() {
    let new_height = this.contentWindow.document.body.offsetHeight + 50;
    if (new_height < 500 && new_height > 60) new_height = 500;
    this.style.height = new_height + 'px'; 
    // scroll to top
    $('#iframe_cms').agile_scroll_view();
  });

/*******************************************************************
 * Same goes for editiframe. Resize it + 30px
 * unless on initial display with no data 
 *******************************************************************/
  $('#iframe_edit').on('load', function() {
    if (this.contentWindow.document.body.offsetHeight > 10) {
      this.style.height = (this.contentWindow.document.body.offsetHeight + 30) + 'px'; 

      $('#iframe_edit').agile_scroll_view();
    }
  });

  /*******************************************************************
   * Same goes for iframe_embedded. Resize it + 30px
   *******************************************************************/
  $('.iframe_embedded').on('load', function() {
    let embedded_height = this.contentWindow.document.body.offsetHeight;
    // workaround. It gets tricky when embedded field is on tab
    if (embedded_height == 0) embedded_height = 50;
    this.style.height = (embedded_height + 30) + 'px';
    // resize parent iframe window too
    let parentWindow = this.contentWindow.parent;
    let parent_height = (parentWindow.document.body.offsetHeight + 30) + 'px';
    //parentWindow.frameElement.setAttribute('style', 'height:' + parent_height);
    parentWindow.frameElement.style.height = parent_height;
    /*
    // register blur event
    this.contentWindow.addEventListener('blur', handleIframeBlurred(this));
    this.contentWindow.addEventListener('focusout', handleIframeBlurred(this));
    this.contentWindow.addEventListener('focus', handleIframeFocus(this));
     */
  });

/*******************************************************************
 * Process Ajax call on form actions
 *******************************************************************/
  $('.ar-link-ajax').on('click', function(e) {
    // confirmation if required
    if (confirmation_is_cancelled(this)) {return false;}

    // url must be specified in data-url
    let url = this.getAttribute("data-url");
    if (url.length < 5) return false;

    // check HTML5 validations
    let validate = this.getAttribute("data-validate");
    if (validate == null || validate == true) {
      if ($("form")[0] && !$("form")[0].checkValidity()) {
        $("form")[0].reportValidity();
        return false;
      }
    }

    // update html editor fields before data serialization
    let cke_elements = document.querySelectorAll(`div[id^="cke_record"]`);
    cke_elements.forEach(e => {
      let field_id = e.id.replace('cke_', '');
      let text = CKEDITOR.instances[field_id].getData();
      $('#' + field_id).val(text);
    });

    let data = {};
    let request = this.getAttribute("data-request");
    switch (request) {
      case 'script':
        eval(this.getAttribute("data-script"));
        return false;

      case 'post':
        data = $('form').serialize();
        break;

      default:
        request = 'get'; // by default
    }

    // add checkbox id-s to data if checkboxes present
    let checkboxes = $('.ar-check');
    if (checkboxes.length > 0) {
      let checked = [];
      checkboxes.each( function() {
        if ($(this).prop('checked')) checked.push($(this).attr("id").replace('check-', ''));
      })
      data['checked'] = checked;
    }

    $('.ar-spinner').show();
    $.ajax({
      url: url,
      type: request,
      dataType: "json",
      data: data,
      success: function(data) {
        process_json_result(data);
        $('.ar-spinner').hide();
      },
      error: function (request, status, error) {
        $('.ar-spinner').css('color','red');
        alert(request.responseText);
      }
    });
  });

  /*******************************************************************
   * Click on filter off
   *******************************************************************/
  $('.mi-filter_alt_off').on('click', function(e) {
    let url = $(this).parents('.ar-filter').attr("data-url");
    if (url.length > 5) simple_ajax_call(url);
  });
  
/*******************************************************************
 * Process action submit button click. 
 *******************************************************************/
  $('.ar-action-submit').on('click', function(e) {
    // confirmation if required
    if (confirmation_is_cancelled(this)) {return false;}
   
    // check HTML5 validations
    var form = $("form")[0];
    if (form && !form.checkValidity() ) {
      form.reportValidity();
      return false;
    }
    var url = this.getAttribute("data-url");
    if (url == null) {return false;}

    form.setAttribute('action', url);
    form.setAttribute('method', "post");
    form.submit();
  });

  /*******************************************************************
    Will open a new window with URL specified.
  ********************************************************************/
  $('.ar-window-open').on('click', function(e) {
    // confirmation if required
    if (confirmation_is_cancelled(this)) return false;

    let url = this.getAttribute("data-url");
    let title = this.getAttribute("title");
    let w = this.getAttribute("data-x") || 1000;
    let h = this.getAttribute("data-y") || 800;

    url = agile_url_add_params(this, url)
    let win = popup_window(url, title, window, w, h);
    win.focus();
  });

  /*******************************************************************
   Will open a new popup with URL specified.
   ********************************************************************/
  $('.ar-popup-open').on('click', function(e) {
    // confirmation if required
    if (confirmation_is_cancelled(this)) return false;

    let url = this.getAttribute("data-url");
    let title = this.getAttribute("title");
    let w = this.getAttribute("data-x") || 1000;
    let h = this.getAttribute("data-y") || 800;

    url = agile_url_add_params(this, url)
    $('#popup').bPopup({ loadUrl: url,
                             transition: 'slideDown', transitionClose: 'slideDown', speed: 300,
                             opacity: 0, position: ['auto', 20],
                             closeClass: 'ar-link'
    });
  });

 /*******************************************************************
 * Animate button on click
 ******************************************************************
  $('.xar-action-menu li').mousedown( function() {
    $(this).toggleClass('ar-animate-button');
  });
  
 ******************************************************************
 * Animate button on click
 ******************************************************************
  $('.xar-action-menu li').mouseup( function() {
    $(this).toggleClass('ar-animate-button'); 
  });
 */

 /*******************************************************************
  * App menu option clicked
  *******************************************************************/
  $('.app-menu-item a').on('click', function(e) { 
/* parent of a is li */
    $(e.target).parents('li').each( function() {
/* for all li's in ul, deselect */
      $(this).parents('ul').find('li').each( function() {
        if ($(this).hasClass('app-menu-item-selected')) {
          $(this).toggleClass('app-menu-item-selected');
        }
      });
/* select clicked li */
      $(this).toggleClass('app-menu-item-selected');
    });
  });

/*******************************************************************
 * Display spinner on link with spinner, submit link
 *******************************************************************/
  $('.ar-link.spin').on('click', function(e) {
    $('.ar-spinner').show();
  });  
  
  $('.ar-link-submit').on('click', function(e) {
    $('.ar-spinner').show();
  });

  /*******************************************************************
   * Hide spinner when validation error occured
   *******************************************************************/
  $(':input').on("invalid", function(event) {
    $('.ar-spinner').hide();
  });

/*******************************************************************
  * Add button clicked while in edit. Create window dialog for adding new record
  * into required table. This is helper scenario, when user is selecting
  * data from with text_autocomplete and data doesn't exist in belongs_to table.
  *******************************************************************/
  $('.in-edit-add').on('click', function(e) {
    let id = this.getAttribute("data-id");
    let table = this.getAttribute("data-table");
    let url = '/agile/new?window_close=0&table=' + table;
    if (id) {
      url = '/agile/' + id + '/edit?window_close=0&table=' + table;
    }
    let w = popup_window(url, '', window, 1000, 800);
    w.focus();    
  });  
  
/**********************************************************************
 * When filter_field (field name) is selected on filter subform this routine finds 
 * and displays appropriate span with input field.
 **********************************************************************/
  $('#filter_field').on('change', function() {
    if (this.value.length > 0) { 
      let name = 'filter_' + this.value;
      $(this).parents('form').find('span').each( function() {

        if ($(this).attr('id') == name) {
          if ( $(this).hasClass('div-hidden') ) { $(this).toggleClass('div-hidden'); }
        } else {
          if ( !$(this).hasClass('div-hidden') ) { $(this).toggleClass('div-hidden'); }
        }
      });         
    } 
  });

  /*******************************************************************
   * Help text is displayed as title when mouse hovered over label.
   * This was not wery obvious so, help icon was added to label
   * and help text is also displayed if user clicks on label text.
   *******************************************************************/
  $('.ar-form-label').on('click', function(e) {
    let titleText = $(this).attr('title');
    if (!titleText || titleText == ' ' ) return;

    $('#popup')
      .text(titleText)
      .css({
        left: e.pageX + 10 + 'px',
        top: e.pageY + 10 + 'px',
        display: 'block'
      });
    $('#popup').addClass('tooltip');

    if (timeoutId) clearTimeout(timeoutId);
    timeoutId = setTimeout(function () {
      $('#popup').css({display: 'none'});
      $('#popup').removeClass('tooltip');
      timeoutId = null;
    }, 3000);
  });

  /*******************************************************************
 * It is not possible to attach any data to submit button except the text
 * that is written on a button and it is therefore very hard to distinguish
 * which button was pressed when more than one button is present on a form.
 * 
 * The purpose of this trigger is to append data hidden in html5 data attributes
 * to the form. We can now attach  any kind of data to submit button and data 
 * will be passed as data[] parameters to controller. 
 *******************************************************************/
  $('.ar-submit').on('click', function() {
    $.each(this.attributes, function() {
      if (this.name.substring(0,5) == 'data-') { 
        $('<input>').attr({
          type: 'hidden',
          name: 'data[' + this.name.substring(5) + ']',
          value: this.value
        }).appendTo('form');
      }
    });
  });
 
 /* DOCUMENT INFO                                                   */ 
 /*******************************************************************
  * Popup or hide document information 
  *******************************************************************/
  $('#ar-document-info').on('click',function(e) { 
    popup = $('#ar-document-info-popup');
    popup.toggleClass('div-hidden'); 
    if (!popup.hasClass('div-hidden')) {
      var o = {
        left: e.pageX - popup.width() - 10,
        top: e.pageY - popup.height() - 20
      };
      popup.offset(o);    
    };
  });
 /*******************************************************************
  * Just hide document information on click.
  *******************************************************************/
  $('#ar-document-info-popup').on('click',function(e) {
    $('#ar-document-info-popup').toggleClass('div-hidden'); 
  });    

/*******************************************************************
 * Experimental. Force reload of parent page if this div appears. 
 *******************************************************************/
  $('#div-reload-parent').on('load', function() {
//    alert('div-reload-parent 1');
    parent.location.href = parent.location.href;
  });

/*******************************************************************
 * Force reload of parent page if this div appears. 
 * 
 * Just an Idea. Not needed yet.
 *******************************************************************/
  $('#div-reload').on('load', function() {
    alert('div-reload 1');
//    location.href = location.href;
  });
  
  $('#div-reload-parent').on('DOMNodeInserted DOMNodeRemoved', function() {
    alert('div-reload-parent 2');
  });  
  $('#div-reload').on('DOMNodeInserted DOMNodeRemoved', function() {
    alert('div-reload 2');
  });
  
 /*******************************************************************
  * Fire action (by default show document) when doubleclicked on result row
  *******************************************************************/
  $('.ar-result tr').on('dblclick', function(e) {
    let url = String( this.getAttribute("data-dblclick") );
    // prevent when data-dblclick not set
    if (url.length > 5) { 
      e.preventDefault();
      location.href = url;
    } 
  });
  
  /*******************************************************************
  * Fire action (by default show document) when doubleclicked on result row
  *******************************************************************/
  $('.ar-result-data').on('dblclick', function(e) {
    let url = String( this.getAttribute("data-dblclick") );
    // prevent when data-dblclick not set
    if (url.length > 5) { 
      e.preventDefault();
      location.href = url;
    } 
  });

 /*******************************************************************
  * Fire action clicked on result row. 
  * TODO: Find out how to prevent event when clicked on action icon.
  *******************************************************************/
  $('.ar-result tr').on('click', function(e) {
    url = String( this.getAttribute("data-click") );
// prevent when data-click not set
    if (url.length > 5) { 
      e.preventDefault();
      location.href = url; 
    } 
  });

 $('#1menu-filter').on('click', function(e) {
    let target = e.target;
    req = target.getAttribute("data-request");
    $('.menu-filter').toggle(300);
  });
  
 /*******************************************************************
  * Pressing Enter in search field will trigger click event on search icon
  * and thus force search event.
  *******************************************************************/
  $('#_record__filter_field').keydown( function(e) {
    if (e.which == '13' || e.which == '9') {
      e.preventDefault();
      $('.record_filter_field_icon').trigger("click")
    };
  });

  /*******************************************************************
  * Will set internal filter value and fire reload event to enable
  * filtering documents on index action.
  *******************************************************************/
  $('.record_filter_field_icon').on('click', function(e) {
    let field = $('#_record__filter_field');
    let url   = $(this).parents('span').attr("data-url");
    let value = null;

    if (field.is(':checkbox')) {
      value = field.is(':checked'); }
    else {
      value = field.val();
    }
    url = url + "&filter_value=" + value;
    simple_ajax_call(url);
  });

 /*******************************************************************
  * Click on show filter form
  *******************************************************************/
  $('#open_ar_filter').on('click', function(e) {
    $('#ar_filter').bPopup({
      transition: 'slideDown',
      transitionClose: 'slideDown',
      speed: 300,
      opacity: 0,
      position: ['auto', 20],
      closeClass: 'ar-link' });
  });
  
  /*******************************************************************
  * Click on preview selected image
  *******************************************************************/
  $('.ar-image-preview').on('click', function(e) {
    let img = $(this).children(":first").attr('src');
    $('#ar-image-preview').bPopup({
          content: 'image', //'ajax', 'iframe' or 'image'
          contentContainer: '#ar-image-preview',
          loadUrl: img,
          opacity: 0
    });
  });
  
 /*******************************************************************
  * Set new filter
  *******************************************************************/
  $('.ar-filter-set').on('click', function(e) {
    let url = $(this).attr( 'data-url' );
    let field = $('select#filter_field1').val();
    let operation  = $('select#filter_oper').val();
    url = url + '&filter_field=' + field + '&filter_oper=' + operation
    simple_ajax_call(url);
   });

  /*******************************************************************
   * Toggle one CMS menu level
   *******************************************************************/
  $('.agile-top-level-menu div').on('click', function(e) {
    $(e.target).siblings('ul').toggle('fast');
    $(e.target).toggleClass('expanded');
  });

  /*******************************************************************
   * Toggle dataset record menu
   *
   * This and additional two event hadlers provide expected behavior of submenus popup and close.
   *******************************************************************/
  $('.ar-result-submenu .mi-more_vert').on('click', function(e) {
    let ul = $(e.target).siblings('ul');
    // hide last selected menu if not the same
    if (typeof agile_last_menu_selected !== 'undefined') { agile_last_menu_selected.hide(); }
    // if menu is past the bottom fix it to bottom
    let menu_bottom = ul.height() + ul.parent().position().top + 20;
    if (menu_bottom > $(document).height()) ul.css('bottom', 0);
    ul.show();
    agile_last_menu_selected = ul;
   });

  /*******************************************************************
   * Result record menu has lost focus. Hide menu.
   *******************************************************************/
  $('.ar-result-submenu ul').hover(function(e) {
  },
    function(e) {
      agile_last_menu_selected.hide();
      agile_last_menu_selected = undefined;
  });

  /*******************************************************************
   * dataset record menu is left open if action is canceled. Ex. delete confirm. This will hide menu.
   *******************************************************************/
  $('.ar-result-submenu ul li').on('click', function(e) {
    if (typeof agile_last_menu_selected !== 'undefined') agile_last_menu_selected.hide();
  });

/*******************************************************************
  * Resize result table columns. For now an idea.
  *******************************************************************/
 /*
   $( ".ar-result-header .spacer" )
  .mouseenter(function() {
    console.log("enter");
  })
  .mouseleave(function() {
    console.log("leave");
  });
*/  
 /*******************************************************************
  * number_field type entered
  *******************************************************************/
   $('.ar-number').on('focus', function(e) {
    var separator = $(this).attr("data-separator") || ',';
    var field = '#' + $(this).attr("id").slice(0,-1);
    var value = $(field).val().replace('.',separator);
    $(this).val( value );
    $(this).select();
   });

  /*******************************************************************
  * number_field type leaved
  *******************************************************************/
  $('.ar-number').on('focusout', function(e) {
    var decimals  = $(this).attr("data-decimal") || 2;
    var delimiter = $(this).attr("data-delimiter") || '.';
    var separator = $(this).attr("data-separator") || ',';
    var currency  = $(this).attr("data-currency") || '';
    var val     = this.value;
    // clear delimiters and replace separator with .
    val = val.replace(delimiter,'');
    val = val.replace(separator,'.');
    val = parseFloat(val).toFixed(decimals);
    var whole, dec, sign;
//    [whole,dec] = val.split('.');
    whole = val.split('.')[0];
    dec   = val.split('.')[1];
// remove negative sign and add at the end
    var sign = whole.substr(0,1);
    if (sign == '-') { 
      whole = whole.substr(1,20);
    } else { 
      sign = '';
    }
// save value to field holding return value and trigger change event
    var field = '#' + $(this).attr("id").slice(0,-1);
    $(field).val(val);
    $(field).trigger("change")
    
// decimal part
    if (decimals == 0) separator = '';
    if (dec == null) dec = '';
    while (dec.length < decimals) dec = dec + '0';
// whole part 
    if (whole == null || whole == '') whole = '0';
    var ar = [];
    while (whole.length > 0) { 
      var pos1 = whole.length - 3
      if (pos1 < 0) pos1 = 0;
      ar.unshift(whole.substr(pos1,3)); 
      whole = whole.slice(0, -3); 
     };
          
    if (delimiter !== '') whole = ar.join(delimiter);
    $(this).val(sign + whole + separator + dec + currency);
   });
   
 /*******************************************************************
  * Key pressed in number_field.
  * - put minus sign in front of input field
  * - replace dot and comma separators when required. Not all numeric pads are created equal.
  * - when enter is pressed, save value to field before form is proccessed
  *******************************************************************/
   $('.ar-number').on('keydown', function(e) {
     // Minus sign. Put it on first place
     if (e.which == 109) {
       if($(this).val().substr(0,1) == '-') {
         $(this).val( $(this).val().substr(1,20));
       } else {
         $(this).val( '-' + $(this).val());
       }
       e.preventDefault();
     }
     // replace , with . if . is separator.
     var separator = $(this).attr("data-separator") || '.';
     var inp = this;
     if (e.which == 188) {
       if (separator == '.') {
         setTimeout(function() {
           inp.value = inp.value.replace(/,/g, '.');
         }, 0);
       }
     }
     // replace . with , if , is separator
     if (e.which == 190) {
       if (separator == ',') {
         setTimeout(function() {
           inp.value = inp.value.replace(/\./g, ',');
         }, 0);
       }
     }

     // Enter means process form. Save the value before form is processed
     if (e.which == 13) {
       var decimals  = $(this).attr("data-decimal") || 2;
       var value = $(this).val().replace(separator,'.');
       var field = '#' + $(this).attr("id").slice(0,-1);
        
       $(field).val( parseFloat(value).toFixed(decimals) );
     }
   });

  /*******************************************************************
   * Slovenian keyboard has comma key instead of dot in numeric pad.
   * This will catch if comma has been pressed and will replace it with dot.
   *******************************************************************/
  $('.date-picker').keypress( function(e) {
    if (e.keyCode !== 44) return;
    var inp = this;
    setTimeout(function() {
      inp.value = inp.value.replace(/,/g, '.');
    }, 0);
  });

 /*******************************************************************
  * Result header sort icon is hoverd. Change background icon to filter.
  *******************************************************************/
  $('.ar-result-header .th i').hover( function() {
    old_sort_icon = '';
    // save old sort icon and replace it with filter icon
    $.each( $(this).attr("class").split(/\s+/), 
      function(index, item) { if (item.match('sort')) { old_sort_icon = item}; }
    );
    $(this).removeClass(old_sort_icon).addClass('mi-ads_click');
  // bring back old sort icon
  }, function() {
    $(this).removeClass('mi-ads_click').addClass(old_sort_icon);
  });

/*******************************************************************
  * Result header sort icon is clicked. Display filter menu for the field.
  *******************************************************************/
  $('.ar-result-header .th i').click( function(e) {
    e.preventDefault();
    if ($(this).hasClass('no-filter')) return;

    // additional click will close dialog when visible
    if ($('.filter-popup').is(':visible')) {
      $('.filter-popup').hide();
      return;
    }
    // retrieve name of current field and set it in popup
    let header = $(this).closest('.th');
    let field_name = header.attr("data-name");
    $('.filter-popup').attr('data-name', field_name);
    // change popup position and show
    $('.filter-popup').css({'top': e.pageY + 5, 'left': e.pageX, 'position': 'absolute'});
    $('.filter-popup').show();    
  });
  
/*******************************************************************
  * Filter operation is clicked on filter popup. Retrieve data and call
  * filter on action.
  *******************************************************************/
  $('.filter-popup li').click( function(e) {
    let url = $(this).data('url');
    let operator = $(this).data('operator');
    let parent = $(this).closest('.filter-popup');
    let field_name = parent.data("name");
    
    url = url + '&filter_field=' + field_name + '&filter_oper=' + operator;
    simple_ajax_call(url);
  });

  /*****************************************************************
   * Toggle div
   ******************************************************************/
  $(".ar-handle").click(function(e) {
    let div= this.getAttribute("data-div");
    agile_div_toggle(div);
    e.stopImmediatePropagation(); // required
  });

  /*******************************************************************
   * Show-Hide CMS menu on hamburger click
   *******************************************************************/
  $('#menu-hamburger').on('click', function(e) {
    $('.agile-container #cms-menu').toggleClass('visible');
  });

  /*******************************************************************
   * Iframe lost focus. Save data
   *******************************************************************/
  $('.iframe_embedded').on('focusout', function(e) {
    console.log('focus out');
  });

  /*******************************************************************
   * Iframe lost focus. Save data
   *******************************************************************/
  $('.iframe_embedded').on('focus', function(e) {
    console.log('focus');
  });

  /*******************************************************************
   * Iframe lost focus. Save data
   *******************************************************************/
  $('.iframe_embedded').on('blur', function(e) {
    console.log('blur');
  });

});

/*******************************************************************
 * Catch ctrl+s key pressed and fire save form event. I press ctrl+s
 * almost every minute. That was a lesson learned years ago when I lost
 * few hours of work on computer lockup ;-(
 *******************************************************************/
$(document).keydown( function(e) {
  if ((e.which == '115' || e.which == '83' ) && (e.ctrlKey || e.metaKey))
  {
    e.preventDefault();
    document.forms[0].submit();
    return false;
  }
  return true;
});

/*******************************************************************
 *******************************************************************
document.addEventListener('focus',function(e)
{
  if (e !== active_iframe) {
    if (active_iframe != null) {
      console.log('drug iframe');
    }
    active_iframe = e.target.ownerDocument;
  }
  console.log(active_iframe);
  console.log(e);
  console.log(e.target.ownerDocument);
},
  true);

/*******************************************************************

 *******************************************************************
$(document).onmousedown( function(e) {
  mouseDown = true;
  console.log("mouse down");  
});

$(document).onmouseup( function(e) {
  mouseDown = false;
  console.log("mouse up");  
});

**/
