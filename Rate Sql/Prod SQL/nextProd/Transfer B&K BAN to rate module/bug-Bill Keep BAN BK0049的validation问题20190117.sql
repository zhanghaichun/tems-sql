
DELETE from bill_keep
where lir_exchange in ('LIR ON04', 'LIR ON36')
and imbalance = 100;
