# This is the main state file for configuring hostapd.

{% from "hostapd/map.jinja" import map with context %}

{% macro card2conf(card, map) -%}
{{ map.conf_dir }}/{{ map.conf_file|replace('.conf', "_{}.conf".format(card)) }}
{%- endmacro %}

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
{%-   set daemon_conf = [] %}
{%-   for card in salt['pillar.get']('hostapd:cardlist', {}) %}
{%-     set entry %}{{ card2conf(card, map) }}{% endset %}
{%-     do daemon_conf.append(entry) %}
{%-   endfor %}
hostapd_activate:
  file.replace:
    - name: {{ map.defaults_file }}
    - pattern: "^(|#)DAEMON_CONF=.*$"
    - repl: "DAEMON_CONF='{{ daemon_conf|join(" ") }}'"
    - watch_in:
      - service: hostapd_service
{%- endif %}      

# Ensure hostapd service is running and autostart is enabled
hostapd_service:
  service.running:
    - name: {{ map.service }}
    - enable: True

{% for card in salt['pillar.get']('hostapd:cardlist', {}).keys() %}
hostapd_config_{{ card }}:
  file.managed:
    - name: {{ card2conf(card, map) }}
    - source: salt://hostapd/files/hostapd.conf.jinja
    - template: jinja  
    - context:
      card: {{ card }}
    - user: {{ map.user }}
    - group: {{ map.group }}
    - mode: {{ map.mode }}  
    - watch_in:
      - service: hostapd_service
{% endfor %}
