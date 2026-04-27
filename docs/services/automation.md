# Home Automation

Devices, sensors, flows, integrations, and local voice assistant pipeline.

Most services run on the **k3s cluster** (`automation` namespace). Hyperion.ng runs on a dedicated Pi.

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/home-assistant.png" class="svc-icon"> Home Assistant

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

The central home automation hub. Integrates with hundreds of devices and services, provides dashboards, automations, and the local voice assistant pipeline.

[:octicons-book-16: Documentation](https://www.home-assistant.io/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/home-assistant/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/esphome.png" class="svc-icon"> ESPHome

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

Firmware builder and OTA manager for ESP8266/ESP32 microcontrollers. Devices are defined in YAML and communicate directly with Home Assistant.

[:octicons-book-16: Documentation](https://esphome.io/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/esphome/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/zigbee2mqtt.png" class="svc-icon"> Zigbee2MQTT

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

Bridges the Zigbee coordinator to MQTT, exposing all Zigbee devices as MQTT entities without a proprietary hub.

[:octicons-book-16: Documentation](https://www.zigbee2mqtt.io/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/zigbee2mqtt/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/mosquitto.png" class="svc-icon"> Mosquitto

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

MQTT message broker. Central message bus for all IoT devices and automation components.

[:octicons-book-16: Documentation](https://mosquitto.org/documentation/) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/mosquitto/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/node-red.png" class="svc-icon"> Node-RED

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

Visual flow-based programming for automation. Used for complex multi-step automations that would be verbose in Home Assistant YAML.

[:octicons-book-16: Documentation](https://nodered.org/docs/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/node-red/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/n8n.png" class="svc-icon"> n8n

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

Workflow automation platform. Connects external APIs, webhooks, and services — used for integrations outside the home network scope.

[:octicons-book-16: Documentation](https://docs.n8n.io/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/n8n/values.yaml)

---

## Govee2MQTT

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

Bridges Govee smart lights to MQTT, exposing them as Home Assistant entities without relying on the Govee cloud API.

[:octicons-book-16: Documentation](https://github.com/wez/govee2mqtt) &nbsp;·&nbsp; [:octicons-file-code-16: values.sops.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/govee2mqtt/values.sops.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/grocy.png" class="svc-icon"> Grocy

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

Household management: grocery tracking, chore schedules, and product inventory with barcode scanning support.

[:octicons-book-16: Documentation](https://grocy.info/) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/grocy/values.yaml)

---

## Piper

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

Local text-to-speech engine. Generates natural-sounding voice output for Home Assistant notifications without sending data to the cloud.

[:octicons-book-16: Documentation](https://github.com/rhasspy/piper) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/piper/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/web-whisper.png" class="svc-icon"> Whisper

<em><img src="https://cdn.simpleicons.org/k3s" style="height:1em;vertical-align:middle;margin-right:4px"> k3s-cluster · <code>automation</code></em>

Local speech-to-text powered by OpenAI Whisper. Used for the Home Assistant local voice assistant pipeline.

[:octicons-book-16: Documentation](https://github.com/openai/whisper) &nbsp;·&nbsp; [:octicons-file-code-16: values.yaml](https://github.com/afonsoc12/homelab/blob/master/kubernetes/apps/automation/whisper/values.yaml)

---

## <img src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/hyperion.png" class="svc-icon"> Hyperion.ng

*rpi-z2w-hyperion**

Ambient LED lighting controller. Captures screen content or applies effects to LED strips connected to the Pi, integrated with Home Assistant for scene control.

[:octicons-book-16: Documentation](https://docs.hyperion-project.org/)
