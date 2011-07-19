#!/usr/bin/env ruby

# cymd2comd - Cyrus to Courier Maildir converter
# copyright (c) 2007 Alex Brem <ab@alexbrem.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# --- readme ---
#
# Actually the conversion itself is a quite simple task, because there's not much
# of a difference between Cyrus and Courier maildirs.
#
# Anyways, use it on your own risk and don't forget to
# BACKUP YOUR DATA BEFORE RUNNING this script!

require 'getoptlong'

SCRIPT_NAME    = "cymd2comd"
SCRIPT_VERSION = "0.2.0"
SCRIPT_CHANGED = "2007-08-25"

class MD
  
  # this class is based upon these specs:
  # http://www.courier-mta.org/maildir.html

  COURIER_FOLDER_SEPARATOR = '.'
  COURIER_MSG_SIZE_TAG = 'S='
  
  ANSI_CLEAR = "\r\033[0K"
  
  attr_accessor :verbose, :debug, :simulate, :seen
  attr_reader :source, :destination
  
  def info str; print str; end
  def verbose *str; print str.join if @verbose; end
  def error str; $stderr.puts "Error: #{str}"; end
  def debug str; puts "DEBUG: #{str}" if @debug; end
  
  def error_exit str, code = 1; error str; exit code; end
  
  def process source, destination, hostname, ignore, target_folder

    require 'pathname'
    require 'find'
    require 'fileutils'

    hostname ||= `hostname`.strip
    error_exit "Please specify a hostname!" if hostname.empty?

    info "Running in SIMULATION MODE... nothing gets written to disk!\n\n" if @simulate
    
    # verify paths
    begin
      @source = Pathname.new source
      error_exit "Not a directory (#{@source.realpath})" unless @source.directory?
      verbose "Source: #{@source.realpath}\n"
      @dest = Pathname.new destination
      error_exit "Not a directory (#{@dest.realpath})" unless @dest.directory?
      error_exit "Can't write to (#{@dest.realpath})" unless @dest.writable?
      verbose "Destination: #{@dest.realpath}\n"
    rescue Errno::ENOENT
      error_exit "Directory does not exist (#{$!})"
    end
    
    # store mails in a subfolder?
    unless @simulate
      begin
        maildirmake '.' + target_folder, @dest.realpath
        verbose "Created folder #{target_folder}...\n"
      rescue RuntimeError
        error_exit $!
      end if target_folder
    end

    # prepare regex to ignore files/folders
    @regex = (ignore ||= []).collect { |x| Regexp.new(x) }
    @regex.unshift(/^cyrus\./) # always ignore: cyrus.cache, cyrus.header, cyrus.index
    @regex.unshift(/^\./)      # ignore dotfiles

    debug @regex
    debug self.inspect

    # processing loop
    cnt = 0
    last_folder = ''
    Find.find(@source.realpath) do |path|
      
      # ignore filter
      @regex.each do |x|
        if File.basename(path) =~ x
          debug "Match: #{x.to_s}"
          verbose "\n < Ignoring #{(File.directory?(path) ? "directory" : "file")}: #{File.basename(path)}"
          Find.prune
        end
      end
      
      # fetch mail info
      stat = File.stat(path)
      filename, dirname = stat.directory? ? [nil,path] : [File.basename(path),File.dirname(path)]
      folder = Pathname.new(dirname).relative_path_from(@source.realpath)

      begin
        last_folder = folder
      end unless last_folder == folder

      # process mail
      if stat.file?
        cnt = cnt + 1

        sub_folder = maildir_path folder.to_s, target_folder, @dest.realpath.to_s
        
        msg_time = Time.now
        msg_new_name = "#{msg_time.to_i}.M#{msg_time.usec}P#{Process.pid}V#{stat.dev}I#{stat.ino}.#{hostname},#{COURIER_MSG_SIZE_TAG}#{stat.size}:2#{@seen ? ',S' : ''}"
        dest_msg = sub_folder[:path_abs] + 'cur/' + msg_new_name

        FileUtils::cp path, dest_msg, {:noop => @simulate}
        print @verbose ? "\n > #{folder}/#{filename} => #{sub_folder[:path_abs]}cur/#{msg_new_name}" : "#{ANSI_CLEAR}Processing maildir: #{folder} [#{rotate cnt}] #{cnt}"

      # create/process mailfolder
      elsif stat.directory?
        
        sub_folder = maildir_path folder.to_s, target_folder, @dest.realpath.to_s
        debug sub_folder.inspect

        # create folder
        begin
          maildirmake sub_folder[:path_rel], @dest.realpath.to_s
        rescue RuntimeError
          error_exit $!
        end unless @simulate
      end

    end

    print !@verbose ? ANSI_CLEAR : "\n", "Finished. #{cnt} emails processed.\n"

  end
  
  # map 'Folder' to '.Folder' and 'Folder/Sub' to '.Folder.Sub' and so on...
  def maildir_path folder, prefix, abs_path
    folder_name = folder.split('/').last
    folder_name = '' if folder_name == '.'
    folder_path_rel = folder.split('/').unshift(prefix).collect { |x| ".#{x}" unless x == '.'}.join
    folder_path_rel.chop! if folder_path_rel[-1] == 46 # ruby 1.9 : .ord
    folder_path_abs = abs_path + '/' + folder_path_rel
    folder_path_abs += '/' unless folder_path_abs[-1] == 47 # ruby 1.9 : .ord
    # folder_path_parent = [abs_path,folder_path_rel.split('/').delete_if{|x| x == '.' + folder_name}].join('.')
    # folder_path_parent += '/' unless folder_path_parent[-1] == 47 # ruby 1.9 : .ord
    {:name => folder_name, :path_rel => folder_path_rel, :path_abs => folder_path_abs}
  end
  
  def maildirmake folder, path
    folder.sub!(/^\./, '') if folder[0] == 46 # ruby 1.9 : .ord
    begin
      File.stat("#{path}/#{folder}")
    rescue Errno::ENOENT
      # imap folder doesn't exist.. so we'll create it
      output, exit_code = nil
      IO.popen("maildirmake -f '#{folder}' '#{path}' 2>&1") do |p|
        output = p.read
        exit_code = Process.waitpid2(p.pid)[1].to_i
      end
      raise output unless exit_code == 0 || exit_code == 256
    end
  end
  
  ROTATOR = [ "|", "/", "-", "\\", "|", "/", "-", "\\" ]
  def rotate cnt; ROTATOR[cnt % 8]; end
  
end

def version_info; "#{SCRIPT_NAME} - version #{SCRIPT_VERSION} (#{SCRIPT_CHANGED})"; end

def exit_help code
  puts version_info
  puts "Copy & convert the mails of a Cyrus users' mailbox (maildir style) into a Courier maildir.", ""
  puts "Usage: #{SCRIPT_NAME} [-vDSVh] -s mailbox_directory -d destination_directory", ""
  puts "Required arguments:",
       "\t-s --source      : Cyrus maildir (a single users' mailbox)",
       "\t-d --destination : an existing Courier users' maildir or an empty direcory", ""
  puts "Optional arguments:",
       "\t-t --hostname    : hostname to be used (default: `hostname -f`)",
       "\t-i --ignore      : regex which gets applied to directory- and filenames",
       "\t                   (may be specified more than once)",
       "\t-t --seen        : mark messages as read",
       "\t-t --target      : target folder (toplevel only and without punctuation, e.g. 'OldMail')",
       "\t-v --verbose     : verbose and informative output",
       "\t-S --simulate    : no mails will be added to the destination dir",
       "\t-D --debug       : a lot of debug output (normally not needed)", ""
  puts "Script information:",
       "\t-h --help",
       "\t-V --version", ""
  puts 'Example:',
       'maildirmake $COURIER_HOME/userfoo',
       'cymd2comd.rb -s $CYRUS_HOME/userfoo -d $COURIER_HOME/userfoo --ignore "(Trash|Templates|Spam|Deleted|Drafts)" --seen --simulate --verbose'
  exit code || 0
end

PARAMS   = { :process => 0, :version => 1, :help => 2, :source => 3, :destination => 4, :hostname => 5, :ignore => 6, :target => 7 }.freeze
FLAGS    = { :none => 0, :verbose => 1, :debug => 2, :simulate => 4, :seen => 8 }.freeze

job = PARAMS[:process]
flags = FLAGS[:none]
source, destination, hostname, ignore, target = nil

opts = GetoptLong.new(
  ["--source",          "-s", GetoptLong::REQUIRED_ARGUMENT],
  ["--destination",     "-d", GetoptLong::REQUIRED_ARGUMENT],
  ["--hostname",        "-n", GetoptLong::REQUIRED_ARGUMENT],
  ["--ignore",          "-i", GetoptLong::REQUIRED_ARGUMENT],
  ["--target",          "-t", GetoptLong::REQUIRED_ARGUMENT],
  ["--seen",            "-r", GetoptLong::NO_ARGUMENT],
  ["--verbose",         "-v", GetoptLong::NO_ARGUMENT],
  ["--debug",           "-D", GetoptLong::NO_ARGUMENT],
  ["--simulate",        "-S", GetoptLong::NO_ARGUMENT],
  ["--help",            "-h", GetoptLong::NO_ARGUMENT],
  ["--version",         "-V", GetoptLong::NO_ARGUMENT]
)

begin
  opts.each do |opt,arg|
    case opt
    when '--source'
      source = arg
    when '--destination'
      destination = arg
    when '--hostname'
      hostname = arg
    when '--ignore'
      (ignore ||= []) << arg
    when '--target'
      target = arg
    when '--seen'
      flags |= FLAGS[:seen]
    when '--verbose'
      flags |= FLAGS[:verbose]
    when '--debug'
      flags |= FLAGS[:debug]
    when '--simulate'
      flags |= FLAGS[:simulate]
    when '--help'
      job = PARAMS[:help]
    when '--version'
      job = PARAMS[:version]
    end
  end
rescue
  exit_help 1
end

case job
when PARAMS[:process]
  md = MD.new
  FLAGS.each_pair do |k,v|
    next if k == :none
    md.instance_variable_set("@#{k}", !(flags & v).eql?(0))
  end
  exit_help 1 if source.nil? || destination.nil?
  STDOUT.sync = true
  md.process source, destination, hostname, ignore, target
  puts
when PARAMS[:version]
  puts version_info
when PARAMS[:help]
  exit_help 1
end

exit 0
