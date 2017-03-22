$ ->
  $("a[data-remote].image-like").on "ajax:success", (e, data, status, xhr) ->
    image_html_id = $(this).attr("id")
    image_id = image_html_id.split("-")[2]
    if data.status == 0
      $("#image-like-#{image_id}>i").attr("class", "fa fa-heart")
      if data.cur_num == 1
        $("#image-like-#{image_id}").parent().append("<span class=\"like-count\">#{data.cur_num}</span>")
      else
        $("#image-like-#{image_id}").next().text(data.cur_num)
    else if data.status == 1
      $("#image-like-#{image_id}>i").attr("class", "fa fa-heart-o")
      if data.cur_num == 0
        $("#image-like-#{image_id}").next().remove()
      else
        $("#image-like-#{image_id}").next().text(data.cur_num)
    else
      alert "点赞出错了"
