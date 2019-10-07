#!/usr/bin/env ruby
# SCRIPT FOURNIT SANS AUCUNE GARANTIE D'AUCUNE SORTE DE LA PART DE FACTURATION.PRO
# FACTURATION.PRO NE POURRA ËTRE TENU POUR RESPONSABLE D'UN QUELCONQUE DYSFONCTIONNEMENT LIE A L'UTILISATION
# DE CE SCRIPT.
# CE SCRIPT VOUS PERMET UNIQUEMENT D'AVOIR UNE BASE POUR VOS DEVELOPPEMENTS SIMILAIRES
#
# Ce script permet de télécharger tous les devis et factures générés via notre outil de manière incrémentale.
# Remarques:
# * les documents déjà téléchargés ne sont pas retéléchargés
# * les factures externes ne peuvent pas être générées par notre outil donc ne sont pas téléchargeables
# * les brouillons ne sont pas téléchargés
#
# Configuration
# copier le fichier config.sample.yml, le remplir avec vos informations d'authentification,
# et enregistrer ce fichier sous le nom config.yml
#
#
# usage :
# ruby ./download.rb
#

USER_AGENT = "BackupApp (support@facturation.pro)" # identifiez votre application avec votre adresse email

# install needed gems if missing
require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'rest-client'
end

require 'fileutils'
require 'yaml'

class Backup
  attr_accessor :max_pages, :config

  def initialize
    if File.exists?("./config.yml")
      self.config = YAML.load_file("./config.yml").each_with_object({}) { |(k,v), h| h[k.to_sym] = v }
    else
      $stderr.puts "Errror: config.yml is missing"
      exit
    end
  end

  def call
    verify_directory
    download_all(:quotes)
    download_all(:invoices)
  end

  private

  def verify_directory
    # check if DIRECTORY exists and create it if needed
    FileUtils.mkdir_p(base_path)
    FileUtils.mkdir_p("#{base_path}/invoices")
    FileUtils.mkdir_p("#{base_path}/quotes")
    puts "--> Created #{base_path}"
  end

  def base_path
    if config[:directory].empty?
      $stderr.puts "Missing directory parameter in config file"
      exit
    end
    @base_path ||= File.expand_path(config[:directory])
  end

  def base_url
    @base_url ||= begin
      if config[:api_id].to_i == 0
        $stderr.puts "Missing api_id in config file"
        exit
      elsif config[:firm_id].to_i == 0
        $stderr.puts "Missing firm_id in config file"
        exit
      elsif config[:api_key].to_s == ''
        $stderr.puts "Missing api_key in config file"
        exit
      end
      "https://#{config[:api_id]}:#{config[:api_key]}@www.facturation.pro/firms/#{config[:firm_id]}"
    end
  end

  def download_all(type)
    self.max_pages = 100
    page = 0
    while page < max_pages
      page += 1
      data = retrieve_bills(type, page)
      break if data.empty? # no more items
      data.each { |item| download_bill(type, item) }
    end
    puts "--> End #{type} download"
  end

  def retrieve_bills(type, page)
    puts "--> Retrieve #{type} list - page #{page}"
    url = "#{base_url}/#{type}.json?order=created&sort=asc&page=#{page}"
    res = RestClient.get(url, { accept: :json, user_agent: USER_AGENT })
    if page == 1 && res.headers[:x_pagination]
      self.max_pages = JSON.parse(res.headers[:x_pagination])['total_pages']
    end
    JSON.parse(res.body)
  end

  def download_bill(type, item)
    filename = "#{item['full_invoice_ref']}.pdf"
    path = File.join(base_path, type.to_s, filename)
    if item['draft']
      # we don't retrieve draft
      puts "* Skipped #{item['id']} : draft"
      return false
    elsif item['external']
      puts "* Skipped #{filename} : external invoice"
      return false
    elsif File.exists?(path)
      puts "* Skipped #{filename} : already exists"
      return false
    end

    raw = RestClient::Request.execute(
    method: :get,
    url: "#{base_url}/invoices/#{item['id']}.pdf?original=1",
    raw_response: true,
    headers: { user_agent: USER_AGENT }
    )
    puts "* Saved #{filename} : #{raw.file.size} bytes"
    FileUtils.mv(raw.file.path, path)
    sleep(1) # we dont want to hammer the API because of quota check
    true
  end
end

Backup.new.call
