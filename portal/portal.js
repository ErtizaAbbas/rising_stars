// Rising Stars staff portal — shared helpers
(function () {
  var cfg = window.RS_CONFIG || {};
  var configured = cfg.SUPABASE_URL && cfg.SUPABASE_URL.indexOf('YOUR-PROJECT') === -1;
  var db = configured ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY) : null;

  var THERAPIES = ['Speech therapy', 'ABA therapy', 'Behaviour therapy', 'Occupational therapy', 'Remedial therapy', 'Art therapy', 'Special education class'];
  var LEVELS = ['', 'Not yet', 'Emerging', 'With help', 'Mostly independent', 'Independent'];
  var STATUS = {
    draft: ['Draft', 'pill-blue'], submitted: ['Awaiting review', 'pill-yellow'],
    approved: ['Approved', 'pill-green'], returned: ['Returned for changes', 'pill-red']
  };

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function $(sel, root) { return (root || document).querySelector(sel); }
  function $all(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }
  function param(name) { return new URLSearchParams(location.search).get(name); }
  function statusPill(s) { var x = STATUS[s] || [s, 'pill-blue']; return '<span class="pill ' + x[1] + '">' + esc(x[0]) + '</span>'; }
  function fmtDate(d) {
    if (!d) return '';
    var dt = new Date(d.length === 10 ? d + 'T00:00:00' : d);
    return dt.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
  }
  function today() { var d = new Date(); d.setMinutes(d.getMinutes() - d.getTimezoneOffset()); return d.toISOString().slice(0, 10); }

  function toast(msg, isError) {
    var t = $('#toast');
    if (!t) { t = document.createElement('div'); t.id = 'toast'; t.setAttribute('role', 'status'); document.body.appendChild(t); }
    t.textContent = msg;
    t.className = 'toast show' + (isError ? ' error' : '');
    clearTimeout(t._h);
    t._h = setTimeout(function () { t.className = 'toast'; }, 3500);
  }

  function notConfigured() {
    document.body.innerHTML = '<div class="setup-msg"><h1>Portal not connected yet</h1><p>Add your Supabase project URL and anon key to <code>portal/config.js</code>. See <code>PORTAL-SETUP.md</code>.</p></div>';
  }

  // Signed-in pages call this first. Redirects to login when signed out.
  async function requireAuth(opts) {
    opts = opts || {};
    if (!db) { notConfigured(); return new Promise(function () {}); }
    var sess = (await db.auth.getSession()).data.session;
    if (!sess) { location.replace('index.html'); return new Promise(function () {}); }
    var res = await db.from('profiles').select('*').eq('id', sess.user.id).single();
    var profile = res.data || { full_name: sess.user.email, role: 'instructor' };
    var isCoord = profile.role === 'coordinator' || profile.role === 'admin';
    if (opts.coordinatorOnly && !isCoord) { location.replace('dashboard.html'); return new Promise(function () {}); }
    renderSidebar(opts.active, profile, isCoord);
    return { user: sess.user, profile: profile, isCoord: isCoord };
  }

  function renderSidebar(active, profile, isCoord) {
    var links = [
      ['dashboard', 'dashboard.html', 'Dashboard'],
      ['note', 'note.html', 'New session note'],
      ['report', 'report.html', 'Progress reports'],
      ['proposal', 'proposal.html', 'Course proposal']
    ];
    if (isCoord) links.push(['students', 'students.html', 'Students &amp; goals']);
    var nav = links.map(function (l) {
      return '<a href="' + l[1] + '"' + (l[0] === active ? ' aria-current="page" class="active"' : '') + '>' + l[2] + '</a>';
    }).join('');
    var el = $('#sidebar');
    el.innerHTML =
      '<a href="../index.html" class="side-logo"><img src="../assets/img/logo.png" alt="Rising Stars website"></a>' +
      '<div class="side-user"><strong>' + esc(profile.full_name) + '</strong><span>' + esc(profile.role) + '</span></div>' +
      '<nav aria-label="Portal">' + nav + '</nav>' +
      '<button type="button" class="side-signout" id="signout">Sign out</button>';
    $('#signout').addEventListener('click', async function () { await db.auth.signOut(); location.replace('index.html'); });
  }

  // Buttons for choosing one option (attendance, engagement, ratings)
  function pillGroup(container, options, value, onChange) {
    container.innerHTML = '';
    options.forEach(function (o) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'choice' + (o.value === value ? ' on' : '');
      b.setAttribute('aria-pressed', o.value === value ? 'true' : 'false');
      if (o.aria) b.setAttribute('aria-label', o.aria);
      if (o.color && o.value === value) { b.style.background = o.color; b.style.borderColor = o.color; }
      b.textContent = o.label;
      b.addEventListener('click', function () { onChange(o.value); });
      container.appendChild(b);
    });
  }

  window.RS = {
    db: db, configured: configured, esc: esc, $: $, $all: $all, param: param,
    statusPill: statusPill, fmtDate: fmtDate, today: today, toast: toast,
    requireAuth: requireAuth, pillGroup: pillGroup, THERAPIES: THERAPIES, LEVELS: LEVELS,
    notConfigured: notConfigured
  };
})();
