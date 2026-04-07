<?php

return [
    'auth_rust' => [
        'url' => env('SERVICES_AUTH_RUST_URL', 'http://auth_rust:3001'),
    ],

    'analytics' => [
        'url' => env('SERVICES_ANALYTICS_URL', 'http://analytics_python:8001'),
    ],

    'verify_dafny' => [
        'url' => env('SERVICES_VERIFY_DAFNY_URL', 'http://verify_dafny:3002'),
    ],

    'booking_dotnet' => [
        'url' => env('SERVICES_BOOKING_DOTNET_URL', 'http://booking_dotnet:5001'),
    ],

    'perf_cpp' => [
        'url' => env('SERVICES_PERF_CPP_URL', 'http://perf_cpp:9001'),
    ],

    'sys_zig' => [
        'url' => env('SERVICES_SYS_ZIG_URL', 'http://sys_zig:9002'),
    ],

    'ai_mojo' => [
        'url' => env('SERVICES_AI_MOJO_URL', 'http://ai_mojo:8002'),
    ],
];