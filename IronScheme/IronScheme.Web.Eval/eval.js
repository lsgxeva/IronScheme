
var edargs = 
{ 
  lineNumbers: true, 
  matchBrackets: true,
  tabMode: 'shift',
  indentUnit: 2 
};

var editor = CodeMirror.fromTextArea(document.getElementById('expr'), edargs);

function hidetext() {
  $('#error').hide();
  $('#output').hide();
  $('#result').hide();
}

function cleartext() {
  $('#error pre').text('');
  $('#output pre').text('');
  $('#result pre').text('');
}

$('#submit').click(function(event) {
  editor.save();
  event.preventDefault();

  var status = $('#status pre');
  var error = $('#error pre');
  var output = $('#output pre');
  var result = $('#result pre');

  hidetext();
  cleartext();

  status.text('Please wait...');

  var x = $.post('index.ss', { expr: $("#expr").val() },
      function(data) {
        status.text("Completed");
        if (data.error != undefined) {
          error.text(data.error);
          error.parent().fadeIn('fast');
        }
        if (data.output != undefined && data.output != '') {
          output.text(data.output);
          output.parent().fadeIn('fast');
        }
        if (data.result != undefined) {
          result.text(data.result);
          result.parent().fadeIn('fast');
        }
      }, 'json');
  x.error(function(data) {
    error.html(data.responseText);
    error.parent().fadeIn('fast');
    status.text('Server Error');
  });
});

function load(id) {
  var status = $('#status pre');
  hidetext();
  cleartext();

  status.text("Loading snippet...");

  var x = $.getJSON('snippet.ss?id=' + id, function(data) {
    status.text("Completed");
    var dl = $('#direct-link');
    dl.attr('href', '?id=' + id);
    dl.text('Direct link');
    editor.setValue(data.content);
  });
  x.error(function() { status.text("Server error"); });
}

$('#load').click(function(event) {
  event.preventDefault();
  load($('#snippets').val());
});

$('#save').click(function(event) {
  event.preventDefault();
  editor.save();

  var status = $('#status pre');
  hidetext();
  cleartext();

  var name = $('#name').val();
  var expr = $('#expr').val();

  if (name == '' || expr == '') {
    status.text("Name or expr is empty");
  }
  else {
    status.text("Saving snippet...");

    var x = $.post('snippet.ss',
            {
              name: name,
              expr: expr
            },
            function(data) {
              if (data.id != undefined) {
                window.location = '?id=' + data.id;
              } else {
                status.text("Error saving snippet: " + data.error);
              }
            }, 'json');
    x.error(function() { status.text("Server error"); });
  }
});


