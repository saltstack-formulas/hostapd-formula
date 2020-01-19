# This is the main state file for configuring hostapd.

{% from "hostapd/map.jinja" import map with context %}

{#- Create card to config mapping #}
{%- set daemon_conf = {} %}
{%- set card_conf = {} %}
{%- for card, data in salt['pillar.get']('hostapd:cardlist', {})|dictsort %}
{%-   set cfg_file = '%s/%s.conf'|format(map.conf_dir, card) %}
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
hostapd_defaults_file:
  file.managed:
    - name: {{ map.defaults_file }}
    - source: salt://hostapd/files/defaults.jinja
    - template: jinja
    - context:
        daemon_conf: {{ daemon_conf | json }}
    - watch_in:
      - service: hostapd_service

hostapd_systemd_unit_addition:
  file.managed:
    - name: /etc/systemd/system/hostapd.service.d/multi-interface.conf
    - makedirs: True
    - contents: |
        [Service]
        ExecStart=
        ExecStart=/usr/sbin/hostapd -P /run/hostapd.pid -B $DAEMON_OPTS{% for card in daemon_conf.keys() %} ${DAEMON_CONF_{{ card }}}{% endfor %}

hostapd_systemd_reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file:  hostapd_systemd_unit_addition
{%- endif %}      


# Ensure hostapd.service is stopped and autostart is disabled
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
