---
layout: page
title: Archive
page_title: Archive
permalink: /archive/
years:
- 2020
- 2019
- 2018
- 2017
- 2016
- 2015
- 2014
---

{% for year in page.years %}
## {{ year }}
  {% include archive.html year=year posts=site.posts %}
{% endfor %}

