#!/usr/bin/env perl
use Dancer;
use FotoboxApp;

set environment => "production";
set startup_info => "false"; 

dance;
