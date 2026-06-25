import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const payload = await req.json()
    const { record } = payload
    
    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Fetch the creditor's profile to get FCM token
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('fcm_token, name')
      .eq('id', record.creditor_id)
      .single()

    if (error || !profile?.fcm_token) {
      return new Response(JSON.stringify({ error: 'FCM token not found' }), { status: 400 })
    }

    // Send FCM Notification
    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`
      },
      body: JSON.stringify({
        to: profile.fcm_token,
        notification: {
          title: 'Settlement Update',
          body: `You received a settlement of ₹${record.amount}`,
        },
        data: {
          settlementId: record.id,
          groupId: record.group_id
        }
      })
    })

    const fcmResult = await fcmResponse.json()
    return new Response(JSON.stringify(fcmResult), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
