json.splits @splits do |split|
  json.id         split.id
  json.name       split.name
  json.order      split.order
  json.vert_gain  split.vert_gain
  json.vert_loss  split.vert_loss
end
