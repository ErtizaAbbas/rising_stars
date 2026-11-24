// Rising Stars — small site helpers (no external libraries)
(function () {
  var WHATSAPP = '923333447861';

  // Keep the footer year current
  document.querySelectorAll('[data-year]').forEach(function (el) {
    el.textContent = new Date().getFullYear();
  });

  // Forms: send the details to Rising Stars on WhatsApp (no server needed)
  document.querySelectorAll('form[data-whatsapp]').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var lines = ['Hello Rising Stars, ' + (form.getAttribute('aria-label') || 'enquiry') + ' from the website:'];
      form.querySelectorAll('input, select, textarea').forEach(function (field) {
        if (!field.id || field.type === 'checkbox') return;
        var label = form.querySelector('label[for="' + field.id + '"]');
        var value = (field.value || '').trim();
        if (value) lines.push((label ? label.textContent.trim() : field.id) + ': ' + value);
      });
      if (lines.length < 2) {
        alertNote(form, 'Please fill in at least one field.');
        return;
      }
      var url = 'https://wa.me/' + WHATSAPP + '?text=' + encodeURIComponent(lines.join('\n'));
      window.open(url, '_blank', 'noopener');
      alertNote(form, 'Opening WhatsApp — just press Send and we will get back to you.');
    });
  });

  function alertNote(form, text) {
    var note = form.querySelector('.form-note');
    if (!note) {
      note = document.createElement('p');
      note.className = 'form-note';
      note.setAttribute('role', 'status');
      form.appendChild(note);
    }
    note.textContent = text;
  }
})();
