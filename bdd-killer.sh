#!/bin/bash

  kill -9 $(ps aux | grep 'puppeteer' | awk '{print $2}') > /dev/null
  kill -9 $(ps aux | grep 'http-server' | awk '{print $2}') > /dev/null
  kill -9 $(ps aux | grep 'cucumber' | awk '{print $2}') > /dev/null
  kill -9 $(ps aux | grep 'yaxy' | awk '{print $2}') > /dev/null
  kill -9 $(ps aux | grep 'node' | awk '{print $2}') > /dev/null