class PostsController < ApplicationController
  before_filter :user_required, :except => [:index, :show]
  before_filter :find_forum, :except => [:new, :create]
  before_filter :find_post,  :except => [:new, :create, :index]
  after_filter  :marked_as_read, :only => [:show]

### Global ###

  def new
    @post = Post.new
    raise ActiveRecord::RecordNotFound.new unless @post && @post.creatable_by?(current_user)
  end

  def create
    @post = Post.new
    @post.attributes = params[:post]
    raise ActiveRecord::RecordNotFound.new unless @post && @post.creatable_by?(current_user)
    if !preview_mode && @post.save
      @post.create_node(:user_id => current_user.id)
      redirect_to forum_posts_url(:forum_id => @post.forum_id), :notice => "Votre message a bien été créé"
    else
      @post.node = Node.new
      render :new
    end
  end

### By forum ###

  def index
    redirect_to @forum
  end

  def show
    raise ActiveRecord::RecordNotFound.new unless @post && @post.readable_by?(current_user)
    # TODO Rails 3
    # redirect_to @post, :status => 301 if @post.has_better_id?
  end

  def edit
    raise ActiveRecord::RecordNotFound.new unless @post && @post.editable_by?(current_user)
  end

  def update
    @post.attributes = params[:post]
    raise ActiveRecord::RecordNotFound.new unless @post && @post.editable_by?(current_user)
    if !preview_mode && @post.save
      redirect_to forum_posts_url, :notice => "Votre message a bien été modifié"
    else
      flash.now[:alert] = "Impossible d'enregistrer ce message"
      render :edit
    end
  end

  def destroy
    raise ActiveRecord::RecordNotFound.new unless @post && @post.deletable_by?(current_user)
    @post.mark_as_deleted
    redirect_to forum_posts_url, :notice => "Votre message a bien été supprimé"
  end

protected

  def find_forum
    @forum = Forum.find(params[:forum_id])
  end

  def find_post
    @post = @forum.posts.find(params[:id])
  end

  def marked_as_read
    current_user.read(@post.node) if current_user
  end

end
