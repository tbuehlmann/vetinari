require 'spec_helper'

describe Vetinari::ISupport do
  describe 'CASEMAPPING' do
    it 'sets CASEMAPPING correctly' do
      subject.parse('bot_nick CASEMAPPING=foobar')
      expect(subject['CASEMAPPING']).to eq('foobar')
    end
  end

  describe 'CHANLIMIT' do
    it 'sets CHANLIMIT correctly having one argument' do
      subject.parse('bot_nick CHANLIMIT=#:120')
      expect(subject['CHANLIMIT']).to eq({'#' => 120})
    end

    it 'sets CHANLIMIT correctly having many argument' do
      subject.parse('bot_nick CHANLIMIT=#+:10,&')
      expect(subject['CHANLIMIT']).to eq({'#' => 10, '+' => 10, '&' => Float::INFINITY})
    end
  end

  describe 'CHANMODES' do
    it 'sets CHANMODES correctly' do
      subject.parse('bot_nick CHANMODES=eIbq,k,flj,CFLMPQcgimnprstz')
      expect(subject['CHANMODES']).to eq({
        'A' => %w(e I b q),
        'B' => %w(k),
        'C' => %w(f l j),
        'D' => %w(C F L M P Q c g i m n p r s t z)
      })
    end
  end

  describe 'CHANNELLEN' do
    it 'sets CHANNELLEN correctly' do
      subject.parse('bot_nick CHANNELLEN=50')
      expect(subject['CHANNELLEN']).to eq(50)
    end
  end

  describe 'CHANTYPES' do
    it 'sets CHANTYPES correctly having one type' do
      subject.parse('bot_nick CHANTYPES=#')
      expect(subject['CHANTYPES']).to eq(['#'])
    end

    it 'sets CHANTYPES correctly having many types' do
      subject.parse('bot_nick CHANTYPES=+#&')
      expect(subject['CHANTYPES']).to eq(%w(+ # &))
    end
  end

  describe 'EXCEPTS' do
    it 'sets EXCEPTS correctly with mode_char' do
      subject.parse('bot_nick EXCEPTS')
      expect(subject['EXCEPTS']).to be_true
    end

    it 'sets EXCEPTS correctly without mode_char' do
      subject.parse('bot_nick EXCEPTS=e')
      expect(subject['EXCEPTS']).to eq('e')
    end
  end

  describe 'IDCHAN' do
    it 'sets IDCHAN correctly having one argument' do
      subject.parse('bot_nick IDCHAN=!:5')
      expect(subject['IDCHAN']).to eq({'!' => 5})
    end

    it 'sets IDCHAN correctly having many arguments' do
      subject.parse('bot_nick IDCHAN=!:5,?:4')
      expect(subject['IDCHAN']).to eq({'!' => 5, '?' => 4})
    end
  end

  describe 'INVEX' do
    it 'sets INVEX correctly having no argument' do
      subject.parse('bot_nick INVEX')
      expect(subject['INVEX']).to be_true
    end

    it 'sets IDCHAN correctly having one argument' do
      subject.parse('bot_nick INVEX=a')
      expect(subject['INVEX']).to eq('a')
    end
  end

  describe 'KICKLEN' do
    it 'sets KICKLEN correctly' do
      subject.parse('bot_nick KICKLEN=100')
      expect(subject['KICKLEN']).to be(100)
    end
  end

  describe 'MAXLIST' do
    it 'sets MAXLIST correctly having one argument' do
      subject.parse('bot_nick MAXLIST=b:25')
      expect(subject['MAXLIST']).to eq({'b' => 25})
    end

    it 'sets MAXLIST correctly having many arguments' do
      subject.parse('bot_nick MAXLIST=b:25,eI:50')
      expect(subject['MAXLIST']).to eq({'b' => 25, 'e' => 50, 'I' => 50})
    end
  end

  describe 'MODES' do
    it 'sets MODES correctly having no argument' do
      subject.parse('bot_nick MODES')
      expect(subject['MODES']).to be(Float::INFINITY)
    end

    it 'sets MODES correctly having one argument' do
      subject.parse('bot_nick MODES=5')
      expect(subject['MODES']).to be(5)
    end
  end

  describe 'NETWORK' do
    it 'sets NETWORK correctly' do
      subject.parse('bot_nick NETWORK=freenode')
      expect(subject['NETWORK']).to eq('freenode')
    end
  end

  describe 'NICKLEN' do
    it 'sets NICKLEN correctly' do
      subject.parse('bot_nick NICKLEN=9')
      expect(subject['NICKLEN']).to be(9)
    end
  end

  describe 'PREFIX' do
    it 'sets PREFIX correctly' do
      subject.parse('bot_nick PREFIX=(ohv)@%+')
      expect(subject['PREFIX']).to eq({'o' => '@', 'h' => '%', 'v' => '+'})
    end
  end

  describe 'SAFELIST' do
    it 'sets SAFELIST correctly' do
      subject.parse('bot_nick SAFELIST')
      expect(subject['SAFELIST']).to be_true
    end
  end

  describe 'STATUSMSG' do
    it 'sets STATUSMSG correctly having one argument' do
      subject.parse('bot_nick STATUSMSG=+')
      expect(subject['STATUSMSG']).to eq(['+'])
    end

    it 'sets STATUSMSG correctly having many arguments' do
      subject.parse('bot_nick STATUSMSG=@+')
      expect(subject['STATUSMSG']).to eq(['@', '+'])
    end
  end

  describe 'STD' do
    it 'sets STD correctly having one argument' do
      subject.parse('bot_nick STD=foo')
      expect(subject['STD']).to eq(['foo'])
    end

    it 'sets STD correctly having many arguments' do
      subject.parse('bot_nick STD=foo,bar,baz')
      expect(subject['STD']).to eq(['foo', 'bar', 'baz'])
    end
  end

  describe 'TARGMAX' do
    it 'sets TARGMAX correctly having limits' do
      subject.parse('bot_nick TARGMAX=NAMES:1,LIST:2,KICK:3')
      expect(subject['TARGMAX']).to eq({'NAMES' => 1, 'LIST' => 2, 'KICK' => 3})
    end

    it 'sets TARGMAX correctly having limits and no limits' do
      subject.parse('bot_nick TARGMAX=NAMES:1,LIST:2,KICK:3,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR:')
      expect(subject['TARGMAX']).to eq({
        'NAMES' => 1,
        'LIST' => 2,
        'KICK' => 3,
        'WHOIS' => 1,
        'PRIVMSG' => 4,
        'NOTICE' => 4,
        'ACCEPT' => Float::INFINITY,
        'MONITOR' => Float::INFINITY
        })
    end
  end

  describe 'TOPICLEN' do
    it 'sets TOPICLEN correctly' do
      subject.parse('bot_nick TOPICLEN=250')
      expect(subject['TOPICLEN']).to be(250)
    end
  end

  describe 'Different' do
    it 'sets non mentioned keys correclty aswell' do
      subject.parse('bot_nick AWAYLEN=160')
      subject.parse('bot_nick CNOTICE')
      subject.parse('bot_nick EXTBAN=$,arx')
      expect(subject['AWAYLEN']).to eq('160')
      expect(subject['CNOTICE']).to be_true
      expect(subject['EXTBAN']).to eq(['$', 'arx'])
    end
  end

  describe 'Several arguments at once' do
    it 'sets several arguments at once correcty' do
      subject.parse('bot_nick CHANTYPES=# EXCEPTS INVEX CHANMODES=eIbq,k,flj,CFLMPQcgimnprstz CHANLIMIT=#:120 PREFIX=(ov)@+ MAXLIST=bqeI:100 MODES=4 NETWORK=freenode KNOCK STATUSMSG=@+ CALLERID=g :are supported by this server')
      subject.parse('bot_nick CASEMAPPING=strict CHARSET=ascii NICKLEN=16 CHANNELLEN=50 TOPICLEN=390 ETRACE CPRIVMSG CNOTICE DEAF=D MONITOR=100 FNC TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR: :are supported by this server')
      subject.parse('bot_nick EXTBAN=$,arx WHOX CLIENTVER=3.0 SAFELIST ELIST=CTU :are supported by this server')
      expect(subject['CHANTYPES']).to eq(['#'])
      expect(subject['EXCEPTS']).to be_true
      expect(subject['INVEX']).to be_true
      expect(subject['CHANMODES']).to eq({
        'A' => %w(e I b q),
        'B' => %w(k),
        'C' => %w(f l j),
        'D' => %w(C F L M P Q c g i m n p r s t z)
        })
      expect(subject['CHANLIMIT']).to eq({'#' => 120})
      expect(subject['MAXLIST']).to eq({'b' => 100, 'q' => 100, 'e' => 100, 'I' => 100})
      expect(subject['MODES']).to be(4)
      expect(subject['KNOCK']).to be_true
      expect(subject['STATUSMSG']).to eq(['@', '+'])
      expect(subject['CALLERID']).to eq('g')
      expect(subject['CASEMAPPING']).to eq('strict')
      expect(subject['CHARSET']).to eq('ascii')
      expect(subject['NICKLEN']).to be(16)
      expect(subject['CHANNELLEN']).to be(50)
      expect(subject['TOPICLEN']).to be(390)
      expect(subject['ETRACE']).to be_true
      expect(subject['CPRIVMSG']).to be_true
      expect(subject['CNOTICE']).to be_true
      expect(subject['DEAF']).to eq('D')
      expect(subject['MONITOR']).to eq('100')
      expect(subject['FNC']).to be_true
      expect(subject['TARGMAX']).to eq({
        'NAMES' => 1,
        'LIST' => 1,
        'KICK' => 1,
        'WHOIS' => 1,
        'PRIVMSG' => 4,
        'NOTICE' => 4,
        'ACCEPT' => Float::INFINITY,
        'MONITOR' => Float::INFINITY
        })
      expect(subject['EXTBAN']).to eq(['$', 'arx'])
      expect(subject['WHOX']).to be_true
      expect(subject['CLIENTVER']).to eq('3.0')
      expect(subject['SAFELIST']).to be_true
      expect(subject['ELIST']).to eq('CTU')
    end
  end
end
