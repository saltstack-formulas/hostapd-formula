# This is the main state file for configuring hostapd.

{% from "hostapd/map.jinja" import map with context %}

{#- Create card to config mapping #}
{%- set daemon_conf = {} %}
{%- set card_conf = {} %}
{%- for card, data in salt['pillar.get']('hostapd:cardlist', {})|dictsort %}
{%-   set cfg_file = '%s/%s_%s.conf'|format(map.conf_dir, map.conf_file|replace('.conf', ''), card) %}
{%-   do daemon_conf.update({card: cfg_file}) %}
{%-   do card_conf.update({card: data}) %}
{%- endfor %}

# Install packages
{%- if map.pkgs is defined %}
hostapd_pkgs:
  pkg.installed:
    - pkgs:
      {% for pkg in map.pkgs %}
      - {{ pkg }}
      {% endfor %}
    - require_in:
      - service: hostapd_service
{%- endif %}      

{%- if map.defaults_file is defined %}
hostapd_activate:
  file.replace:
    - name: {{ map.defaults_file }}
    - pattern: "^(|#)DAEMON_CONF=.*$"
    - repl: "DAEMON_CONF='{{ daemon_conf.values()|join(" ") }}'"
    - watch_in:
      - service: hostapd_service
{%- endif %}      

# Ensure hostapd service is running and autostart is enabled
hostapd_service:
  service.running:
    - name: {{ map.service }}
    - enable: True

{% for card, conf in daemon_conf|dictsort %}
hostapd_config_{{ card }}:
  file.managed:
    - name: {{ conf }}
    - source: salt://hostapd/files/hostapd.conf.jinja
    - template: jinja  
    - context:
      card: {{ card }}
      card_data: {{ card_conf[card] | json }}
    - user: {{ map.user }}
    - group: {{ map.group }}
    - mode: {{ map.mode }}  
    - watch_in:
      - service: hostapd_service
{% endfor %}
