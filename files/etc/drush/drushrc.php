<?php

if (!empty($_ENV['DDEV_BASE_URL'])) {
    $options['uri'] = $_ENV['DDEV_BASE_URL'];
}