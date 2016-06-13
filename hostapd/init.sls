# This is the main state file for configuring hostapd.

{% from "hostapd/map.jinja" import map with context %}

# Install packages
hostapd_pkgs:
  pkg.installed:
    - pkgs:
      {% for pkg in map.pkgs %}
      - {{ pkg }}
      {% endfor %}

{%- if map.defaults_file is defined %}
hostapd_activate:
  file.append:
    - name: {{ map.defaults_file }}
    - text: DAEMON_CONF="{{ map.conf_dir }}/{{ map.conf_file }}"  
{%- endif %}      

# Ensure hostapd service is running and autostart is enabled
hostapd_service:
  service.running:
    - name: {{ map.service }}
    - enable: True
    - require:
      - pkg: hostapd_pkgs

# Deploy hostapd.conf
hostapd_config:
  file.managed:
    - name: {{ map.conf_dir }}/{{ map.conf_file }}
    - source: salt://hostapd/files/hostapd.conf.jinja
    - template: jinja  
    - user: {{ map.user }}
    - group: {{ map.group }}
    - mode: {{ map.mode }}  
    - watch_in:
      - service: hostapd_service
