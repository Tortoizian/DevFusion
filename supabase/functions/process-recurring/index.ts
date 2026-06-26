import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Find all recurring expenses where next_run_at is past
    const now = new Date().toISOString()
    const { data: recurring, error: fetchError } = await supabase
      .from('recurring_expenses')
      .select('*')
      .lte('next_run_at', now)

    if (fetchError) throw fetchError

    for (const item of recurring || []) {
      // Create new expense
      const { error: insertError } = await supabase.from('expenses').insert({
        group_id: item.group_id,
        description: item.description,
        amount: item.amount,
        payer_id: item.payer_id,
        category: 'utilities',
        split_type: 'equal' // simplifying for the demo
      })

      if (!insertError) {
        // Update next_run_at based on interval
        const nextRun = new Date(item.next_run_at)
        if (item.interval === 'daily') nextRun.setDate(nextRun.getDate() + 1)
        else if (item.interval === 'weekly') nextRun.setDate(nextRun.getDate() + 7)
        else if (item.interval === 'monthly') nextRun.setMonth(nextRun.getMonth() + 1)
        else if (item.interval === 'yearly') nextRun.setFullYear(nextRun.getFullYear() + 1)

        await supabase
          .from('recurring_expenses')
          .update({ next_run_at: nextRun.toISOString() })
          .eq('id', item.id)
      }
    }

    return new Response(JSON.stringify({ processed: recurring?.length || 0 }), {
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
