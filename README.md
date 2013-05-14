# Vetinari [![Gem Version](https://badge.fury.io/rb/vetinari.png)](http://badge.fury.io/rb/vetinari)
Vetinari is a Domain Specific Language for writing IRC Bots using the [Celluloid::IO](https://github.com/celluloid/celluloid-io "Celluloid::IO") library.

## Requirements
- Ruby >= 1.9.2
- Celluloid::IO ~> 0.14

## Wiki
Detailed information about using Vetinari can be found in the [Project Wiki](https://github.com/tbuehlmann/vetinari/wiki).

## Quick Setup

### Installation
```sh
$ gem install vetinari
```

### Usage
```ruby
require 'vetinari'

bot = Vetinari::Bot.new do |config|
  config.server = 'chat.freenode.org'
  config.port   = 6667
  config.nick   = 'Vetinari'
end

bot.on(:connect) do
  bot.join '#vetinari'
end

bot.on(:channel, :pattern => /foo/) do |env|
  env[:channel].message('bar')
end

bot.connect
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
Copyright (c) 2013 Tobias Bühlmann

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
