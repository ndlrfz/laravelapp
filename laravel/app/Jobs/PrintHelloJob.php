<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log; // Import the Log facade

class PrintHelloJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $name; // Add a property to store the name

    public function __construct($name) // Constructor to receive the name
    {
        $this->name = $name;
    }

    public function handle()
    {
        // Log the message with the provided name
        Log::info("Hello from the queue! My name is: " . $this->name);

        // Or, you can just print it to the console if you prefer
        // This is useful for testing in development
        // echo "Hello from the queue! My name is: " . $this->name . "\n";
    }
}
