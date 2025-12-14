<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'type',
        'location',
        'description',
        'status',
        'priority',
        'reporter_name',
        'reporter_ic',
        'reporter_contact',
        'date_reported',
        'date_updated',
        'admin_notes',
        'image_url',
    ];

    protected $casts = [
        'date_reported' => 'datetime',
        'date_updated' => 'datetime',
    ];
}
