class ImageController < ApplicationController
  include ImageHelper
  include TimeHelper

  before_action :require_login

  def item
    @image = Image.find(params[:id])
    @likes = @image.likes
    @comments = @image.comments

    @image.liked = false
    if logged_in?
      @likes.each do |like|
        @image.liked = true if like.user_id == current_user.id
      end
    end
  end

  def explore
    @explore = {}
    @explore[:weekly_top] = weekly_top_list
    render "image/explore"
  end

  def digest
    digest = weekly_digest_photos
    unless params[:email].blank?
      if params[:email] == "all"
        @users = User.all
        @users.each do |u|
          I18n.with_locale(u.locale) do
            UserMailer.featured_photo(u, digest).deliver_now
          end
        end
      else
        @user = current_user
        @user.email = "226225555@qq.com"
        UserMailer.featured_photo(@user, digest).deliver_now
      end

      render plain: "sent"
      return
    end
    render plain: "not mail address"
  end

  def upload
  end

  def create
    @image = Image.new(params.require(:image).permit(:title, :url, :img_file))
    @image.user = User.find(current_user.id)

    if @image.save
      flash[:info] = I18n.t(:upload_success)
    else
      flash[:warning] = @image.errors.messages
    end

    redirect_to root_url
  end

  def comment
    image_id = params[:id]
    user_id = current_user.id

    @comment = Comment.new
    params.require(:comment).permit(:content)
    @comment.content = params[:comment][:content]
    @comment.user_id = user_id
    @comment.image_id = image_id
    @comment.status = Comment::STATUS_OK
    @comment.save

    # notify
    send_notification(@comment.id, @comment.user_id, Image.find(image_id).user_id, :comment)

    # render
    redirect_to "/image/#{image_id}"
  end

  def like
    image_id = params[:id]
    user_id = current_user.id

    result = {
      :status => nil,
      :cur_num => nil
    }
    
    # check existence
    @like = Like.unscoped.find_by(image_id: image_id, user_id: user_id, status: [Like::STATUS_LIKE, Like::STATUS_UNLIKE])

    unless @like == nil
      if @like.status == Like::STATUS_LIKE
        @like.status = Like::STATUS_UNLIKE
        result[:status] = Like::STATUS_UNLIKE
      else
        @like.status = Like::STATUS_LIKE
        result[:status] = Like::STATUS_LIKE
      end
      
      if @like.save
        result[:cur_num] = get_likes_num(image_id)
      else
        result[:status] = -1
      end
    else
      if new_like(image_id, user_id)
        result[:status] = Like::STATUS_LIKE
        result[:cur_num] = get_likes_num(image_id)
      else
        result[:status] = -2
      end
    end

    if result[:status] == Like::STATUS_LIKE
      send_notification(@like.id, user_id, Image.find(image_id).user_id, :like)
    end

    # render
    respond_to do |format|
      format.json do
        render json: result
      end
    end
  end

  private
  def require_login
    unless logged_in?
      flash[:warning] = I18n.t(:login_required)
      redirect_to root_url
    end
  end

  def send_notification(event_id, from_user_id, to_user_id, type)
    return if from_user_id == to_user_id
    notif = Notification.new
    notif.user_id = to_user_id
    notif.event_type = Notification::NOTIFICATION_TYPES[type]
    notif.event_id = event_id
    notif.status = Notification::STATUS_OK
    notif.event_from_user_id = from_user_id
    notif.save
    logger.info notif.inspect
    logger.info notif.errors.inspect
  end

  def new_like(image_id, user_id)
    # add new
    @initial_like = Like.new
    @initial_like.user_id = user_id
    @initial_like.image_id = image_id
    @initial_like.status = Like::STATUS_LIKE
    @initial_like.save
  end

  def get_likes_num(image_id)
    Like.unscoped.select("id").where(image_id: image_id, status: Like::STATUS_LIKE).count
  end

  def weekly_top_list
    Image.unscoped.joins(:likes).group("likes.image_id").order("count(likes.id) desc").limit(30)
  end

  def weekly_digest_photos
    Image.unscoped.where(url: "").joins(:likes).group("likes.image_id").order("created_at desc, count(likes.id) desc").limit(10)
  end
end
