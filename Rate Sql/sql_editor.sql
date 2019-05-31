insert into audit_mrc_variance(invoice_id, stripped_circuit_number, mrc_previous, mrc_current, 
  mrc_variance, occ, audit_circuit_status, audit_rate_status, variance_reason_id, variance_notes)
values(534348, '452156IGDK4556156', 36, 25, 11, -56, 2, 1, 3, 'good one'),
(534348, '452548IGDK4556156', 25, 21, 4, -27, 1, 1, 2, 'beautiful soup'),
(534348, '452156IGDK4302156', 14, 7, 7, -31, 2, 2, 1, 'requests');


insert into variance_reason(variance_reason_name)
  values('New Install'),
  ('Rate Changed'),
  ('Disconnected');