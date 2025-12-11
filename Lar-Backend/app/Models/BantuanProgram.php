<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BantuanProgram extends Model
{
    protected $fillable = [
        'title',
        'description',
        'category',
        'criteria',
        'program_type',
        'aid_amount',
        'start_date',
        'end_date',
        'status',
        'admin_id',
        'admin_remarks',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Get the admin who created/updated this program
    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
