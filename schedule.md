---
layout: page
title: Schedule
description: The weekly schedule.
nav_order: 2
---

# Schedule

Keep in mid that all the code to generate this website and the class notes can be found on [GitHub](https://github.com/stat870/fall2025). 

{% for module in site.modules %}
{{ module }}
{% endfor %}
