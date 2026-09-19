#!/bin/sh
# Shared functions for all CGI scripts

NAV='<nav>
<ul><li><a href="/cgi-bin/status" class="brand">&#129503; ZOMBIE740</a></li></ul>
<ul>
<li><a href="/cgi-bin/status" '"$([ "${PATH_INFO:-$SCRIPT_NAME}" = "/cgi-bin/status" ] && echo 'class="active"')"'>Status</a></li>
<li><a href="/cgi-bin/network">Siec</a></li>
<li><a href="/cgi-bin/dhcp">DHCP/DNS</a></li>
<li><a href="/cgi-bin/firewall">Firewall</a></li>
<li><a href="/cgi-bin/diag">Diagnostyka</a></li>
<li><a href="/cgi-bin/system">System</a></li>
<li><a href="/cgi-bin/logout" class="logout">Wyloguj</a></li>
</ul></nav>'

html_head() {
    local title="$1"
    local active="$2"
    echo "Content-Type: text/html; charset=utf-8"
    echo ""
    cat << HTML
<!DOCTYPE html>
<html lang="pl" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ZOMBIE740 — ${title}</title>
<link rel="stylesheet" href="/pico.min.css">
<style>
:root{--pico-font-size:15px}
nav{padding:.6rem 1.2rem;border-bottom:1px solid var(--pico-muted-border-color)}
nav .brand{font-weight:700;font-size:1.1rem;letter-spacing:1px;color:var(--pico-primary);text-decoration:none}
nav ul{margin:0}
nav ul li a{padding:.3rem .7rem;border-radius:4px;font-size:.88rem}
nav ul li a.active{background:var(--pico-primary-background);color:var(--pico-primary)}
nav ul li a.logout{color:var(--pico-muted-color);font-size:.82rem}
nav ul li a.logout:hover{color:#f44336}
main{max-width:1100px;margin:0 auto;padding:1.5rem 1.2rem}
.g2{display:grid;grid-template-columns:repeat(2,1fr);gap:1.5rem;margin-bottom:1.5rem}
.g4{display:grid;grid-template-columns:repeat(4,1fr);gap:1rem;margin-bottom:1.5rem}
@media(max-width:768px){.g2,.g4{grid-template-columns:1fr}}
.card{background:var(--pico-card-background-color);border:1px solid var(--pico-muted-border-color);border-radius:8px;padding:1.2rem;margin-bottom:1.5rem}
.sec{font-size:.85rem;text-transform:uppercase;letter-spacing:1px;color:var(--pico-muted-color);margin-bottom:.8rem;border-bottom:1px solid var(--pico-muted-border-color);padding-bottom:.4rem}
.lbl{font-size:.75rem;color:var(--pico-muted-color);text-transform:uppercase;letter-spacing:.5px;margin-bottom:.3rem}
.val{font-size:1.4rem;font-weight:600;margin:0}
th{font-size:.78rem;text-transform:uppercase;letter-spacing:.5px;color:var(--pico-muted-color)}
table{margin-bottom:0}
.ok{color:#4caf50}.warn{color:#ff9800}.err{color:#f44336}
.badge{display:inline-block;padding:.15rem .5rem;border-radius:20px;font-size:.75rem;font-weight:600}
.bg{background:#1b3a1f;color:#4caf50}
.br{background:#3a1b1b;color:#f44336}
.bb{background:#1b2e3a;color:#2196f3}
input,select{margin-bottom:0}
label{font-size:.82rem;margin-bottom:.2rem;display:block;color:var(--pico-muted-color)}
button.sm{padding:.4rem .8rem;font-size:.82rem;margin:0}
button.danger{background:transparent;border-color:#f44336;color:#f44336}
button.danger:hover{background:#f44336;color:white}
.row2{display:grid;grid-template-columns:1fr auto;gap:.6rem;align-items:end;margin-bottom:.6rem}
.row3{display:grid;grid-template-columns:1fr 1fr auto;gap:.6rem;align-items:end;margin-bottom:.6rem}
.row4{display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:.6rem;align-items:end;margin-bottom:.6rem}
.hint{font-size:.78rem;color:var(--pico-muted-color);margin-top:.3rem}
pre{font-size:.78rem;max-height:200px;overflow-y:auto;margin:0;background:var(--pico-code-background-color);padding:.8rem;border-radius:6px}
.flash-ok{background:#1b3a1f;border:1px solid #4caf50;color:#4caf50;padding:.8rem 1rem;border-radius:6px;margin-bottom:1rem}
.flash-err{background:#3a1b1b;border:1px solid #f44336;color:#f44336;padding:.8rem 1rem;border-radius:6px;margin-bottom:1rem}
</style>
</head>
<body>
<nav>
<ul><li><a href="/cgi-bin/status" class="brand">&#129503; ZOMBIE740</a></li></ul>
<ul>
<li><a href="/cgi-bin/status"$([ "$active" = "status" ] && echo ' class="active"')>Status</a></li>
<li><a href="/cgi-bin/network"$([ "$active" = "network" ] && echo ' class="active"')>Siec</a></li>
<li><a href="/cgi-bin/dhcp"$([ "$active" = "dhcp" ] && echo ' class="active"')>DHCP/DNS</a></li>
<li><a href="/cgi-bin/firewall"$([ "$active" = "firewall" ] && echo ' class="active"')>Firewall</a></li>
<li><a href="/cgi-bin/diag"$([ "$active" = "diag" ] && echo ' class="active"')>Diagnostyka</a></li>
<li><a href="/cgi-bin/system"$([ "$active" = "system" ] && echo ' class="active"')>System</a></li>
<li><a href="/cgi-bin/logout" class="logout">Wyloguj &#8594;</a></li>
</ul></nav>
<main>
HTML
}

html_foot() {
    echo "</main></body></html>"
}

urldecode() {
    printf '%b' "$(echo "$1" | sed 's/+/ /g; s/%/\\x/g')"
}

parse_post() {
    local data
    read -n "${CONTENT_LENGTH:-0}" data 2>/dev/null
    echo "$data"
}

get_param() {
    local data="$1" key="$2"
    echo "$data" | tr '&' '\n' | grep "^${key}=" | head -1 | cut -d= -f2- | \
        sed 's/+/ /g; s/%/\\x/g' | xargs printf '%b'
}

sanitize() {
    echo "$1" | tr -cd 'a-zA-Z0-9._:/- '
}
