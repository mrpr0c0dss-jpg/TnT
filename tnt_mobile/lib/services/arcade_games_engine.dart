import '../models/mini_game_model.dart';

class ArcadeGamesEngine {
  static final List<MiniGameModel> defaultGames = [
    const MiniGameModel(
      id: 'roblox_obby_3d',
      title: 'Roblox: 3D Obby Parkour',
      subtitle: 'Jump across platforms, dodge lava & collect Robux coins',
      category: '3D Action / Obby',
      icon: '🧱',
      iconImage: 'assets/games/roblox.webp',
      banner: 'assets/games/roblox.webp',
      rating: 4.9,
      playsCount: '54.2K Plays',
      rewardCoins: 25,
      likeRatio: '98%',
      activePlaying: '54.2K',
      developer: 'Roblox Games Inc',
    ),
    const MiniGameModel(
      id: 'bloxd_io_3d',
      title: 'Bloxd.io: 3D BedWars & Obby',
      subtitle: 'Real 3D voxel multiplayer parkour, Roblox-style obby & building with full mobile touch',
      category: '3D WebGL / Voxel',
      icon: '⛏️',
      iconImage: 'assets/games/bloxd_io.webp',
      banner: 'assets/games/bloxd_io.webp',
      externalUrl: 'https://bloxd.io/',
      rating: 4.9,
      playsCount: '168K Plays',
      rewardCoins: 35,
      likeRatio: '97%',
      activePlaying: '168K',
      developer: 'Arthur & Bloxd Team',
    ),
    const MiniGameModel(
      id: 'hexgl_3d_racer',
      title: 'HexGL: 3D Sci-Fi Racer',
      subtitle: 'High-speed 3D futuristic anti-gravity hovercraft racing with dynamic curves & touch steering',
      category: '3D WebGL / Racing',
      icon: '🏎️',
      iconImage: 'assets/games/hexgl.webp',
      banner: 'assets/games/hexgl.webp',
      externalUrl: 'https://hexgl.bkcore.com/play/',
      rating: 4.8,
      playsCount: '89K Plays',
      rewardCoins: 30,
      likeRatio: '95%',
      activePlaying: '89.4K',
      developer: 'BKcore Studios',
    ),
    const MiniGameModel(
      id: 'smash_karts_3d',
      title: 'Smash Karts: 3D Battle Arena',
      subtitle: 'Multiplayer 3D kart battle royale with missile launchers, powerups & drift combat',
      category: '3D WebGL / Action',
      icon: '🚀',
      iconImage: 'assets/banner/neon_loot_battle_royale.webp',
      banner: 'assets/banner/neon_loot_battle_royale.webp',
      externalUrl: 'https://smashkarts.io/',
      rating: 4.9,
      playsCount: '112K Plays',
      rewardCoins: 40,
      likeRatio: '96%',
      activePlaying: '112K',
      developer: 'Smash Karts Arena',
    ),
    const MiniGameModel(
      id: 'shell_shockers_3d',
      title: 'Shell Shockers: 3D FPS Arena',
      subtitle: 'Famous 3D WebGL competitive first-person shooter with multiplayer arenas',
      category: '3D WebGL / FPS',
      icon: '🎯',
      iconImage: 'assets/games/battleground.webp',
      banner: 'assets/games/battleground.webp',
      externalUrl: 'https://shellshock.io/',
      rating: 4.8,
      playsCount: '94K Plays',
      rewardCoins: 35,
      likeRatio: '94%',
      activePlaying: '94.1K',
      developer: 'Blue Wizard Digital',
    ),
    const MiniGameModel(
      id: 'cyber_space_shooter',
      title: 'Cyber Space Defender',
      subtitle: 'Dodge meteors, blast alien drones & rack up combos',
      category: 'Sci-Fi Shooter',
      icon: '🛸',
      iconImage: 'assets/banner/tnt_esports_arena.webp',
      banner: 'assets/banner/neon_loot_battle_royale.webp',
      rating: 4.8,
      playsCount: '21.7K Plays',
      rewardCoins: 20,
      likeRatio: '93%',
      activePlaying: '21.7K',
      developer: 'Cyber Retro Lab',
    ),
    const MiniGameModel(
      id: 'diamond_merge_2048',
      title: 'Diamond Rush 2048',
      subtitle: 'Merge glowing diamonds to unlock the Grand Vault',
      category: 'Puzzle / Strategy',
      icon: '💎',
      iconImage: 'assets/games/clashofclans.webp',
      banner: 'assets/banner/tnt_esports_arena.webp',
      rating: 4.7,
      playsCount: '18.9K Plays',
      rewardCoins: 15,
      likeRatio: '95%',
      activePlaying: '18.9K',
      developer: 'Puzzle Master Studio',
    ),
    const MiniGameModel(
      id: 'poki_games_hub',
      title: 'Poki: 1,000+ Online Games',
      subtitle: 'Instant mobile web games hub: Subway Surfers, Stickman, Racing & Action with zero install',
      category: 'Poki / Hub',
      icon: '👾',
      iconImage: 'assets/games/poki.jpg',
      banner: 'assets/games/poki.jpg',
      externalUrl: 'https://poki.com/',
      rating: 4.9,
      playsCount: '320K Plays',
      rewardCoins: 30,
      likeRatio: '98%',
      activePlaying: '320K',
      developer: 'Poki BV',
    ),
    const MiniGameModel(
      id: 'poki_subway_surfers',
      title: 'Subway Surfers (Poki)',
      subtitle: 'Dodge oncoming trains, surf the tracks, collect coins & unlock hoverboards',
      category: 'Poki / Runner',
      icon: '🛹',
      iconImage: 'assets/games/subway_surfers.jpg',
      banner: 'assets/games/subway_surfers.jpg',
      externalUrl: 'https://poki.com/en/g/subway-surfers',
      rating: 4.9,
      playsCount: '245K Plays',
      rewardCoins: 35,
      likeRatio: '98%',
      activePlaying: '245K',
      developer: 'SYBO & Kiloo',
    ),
    const MiniGameModel(
      id: 'poki_drive_mad',
      title: 'Drive Mad: 3D Stunt (Poki)',
      subtitle: 'Crazy 4x4 monster truck stunt physics, navigate tricky obstacles & finish tracks',
      category: 'Poki / 3D Racing',
      icon: '🚙',
      iconImage: 'assets/games/drive_mad.jpg',
      banner: 'assets/games/drive_mad.jpg',
      externalUrl: 'https://poki.com/en/g/drive-mad',
      rating: 4.8,
      playsCount: '175K Plays',
      rewardCoins: 30,
      likeRatio: '96%',
      activePlaying: '175K',
      developer: 'Fancade / Martin Magni',
    ),
  ];

  static String getGameHtml(String gameId) {
    switch (gameId) {
      case 'roblox_obby_3d':
        return _getRobloxObbyHtml();
      case 'cyber_space_shooter':
        return _getSpaceShooterHtml();
      case 'diamond_merge_2048':
        return _getDiamondMergeHtml();
      default:
        return _getRobloxObbyHtml();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. ROBLOX 3D OBBY PARKOUR (HTML5 CANVAS + WEB AUDIO + TOUCH PAD)
  // ---------------------------------------------------------------------------
  static String _getRobloxObbyHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Roblox 3D Obby Parkour</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; touch-action: manipulation; }
    body, html { width: 100%; height: 100%; overflow: hidden; background: #0B0F19; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    #canvas-container { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
    canvas { width: 100%; height: 100%; display: block; }
    
    /* HUD Header */
    #hud {
      position: absolute; top: 12px; left: 14px; right: 14px;
      display: flex; justify-content: space-between; align-items: center;
      pointer-events: none; z-index: 10;
    }
    .hud-badge {
      background: rgba(15, 23, 42, 0.85); backdrop-filter: blur(8px);
      padding: 6px 14px; border-radius: 20px;
      border: 1px solid rgba(255, 255, 255, 0.15);
      color: #fff; font-size: 13px; font-weight: bold;
      display: flex; align-items: center; gap: 6px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    }
    .hud-robux { color: #10B981; }
    
    /* Touch Controls */
    #touch-controls {
      position: absolute; bottom: 20px; left: 16px; right: 16px;
      display: flex; justify-content: space-between; align-items: flex-end;
      z-index: 10;
    }
    .ctrl-group { display: flex; gap: 12px; }
    .btn-ctrl {
      width: 66px; height: 66px; border-radius: 50%;
      background: rgba(30, 41, 59, 0.82); border: 2px solid rgba(255, 255, 255, 0.25);
      color: #fff; font-size: 24px; font-weight: bold;
      display: flex; align-items: center; justify-content: center;
      user-select: none; -webkit-user-select: none;
      box-shadow: 0 6px 16px rgba(0,0,0,0.4);
      transition: transform 0.05s, background 0.05s;
    }
    .btn-ctrl:active, .btn-ctrl.active {
      transform: scale(0.92);
      background: #0B5CDB; border-color: #38BDF8;
    }
    .btn-jump {
      width: 76px; height: 76px;
      background: linear-gradient(135deg, #10B981, #059669);
      border-color: #34D399; font-size: 16px;
    }
    .btn-jump:active { background: #047857; }

    /* Overlay Screens */
    #game-over-modal {
      display: none; position: absolute; inset: 0;
      background: rgba(11, 15, 25, 0.92); backdrop-filter: blur(10px);
      flex-direction: column; align-items: center; justify-content: center;
      padding: 24px; z-index: 20; color: #fff; text-align: center;
    }
    #game-over-modal.show { display: flex; }
    .modal-card {
      background: #1E293B; border: 1.5px solid #334155;
      border-radius: 20px; padding: 26px 22px; width: 100%; max-width: 320px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.6);
    }
    .btn-play-again {
      width: 100%; padding: 13px; margin-top: 18px;
      background: linear-gradient(135deg, #0B5CDB, #2563EB);
      border: none; border-radius: 12px; color: #fff;
      font-size: 15px; font-weight: bold; cursor: pointer;
      box-shadow: 0 4px 14px rgba(11, 92, 219, 0.4);
    }
  </style>
</head>
<body>
  <div id="hud">
    <div class="hud-badge">🏁 Stage <span id="stage-val">1</span></div>
    <div class="hud-badge hud-robux">💎 <span id="robux-val">0</span> R\$</div>
    <div class="hud-badge">⭐ Score: <span id="score-val">0</span></div>
  </div>

  <div id="canvas-container">
    <canvas id="gameCanvas"></canvas>
  </div>

  <div id="touch-controls">
    <div class="ctrl-group">
      <div class="btn-ctrl" id="btn-left">◀</div>
      <div class="btn-ctrl" id="btn-right">▶</div>
    </div>
    <div class="btn-ctrl btn-jump" id="btn-jump">JUMP</div>
  </div>

  <div id="game-over-modal">
    <div class="modal-card">
      <div style="font-size: 48px; margin-bottom: 8px;">💥</div>
      <h2 style="font-size: 22px; margin-bottom: 6px;">Obby Finished!</h2>
      <p style="color: #94A3B8; font-size: 13px; margin-bottom: 16px;">You conquered the obstacle platforms!</p>
      <div style="background: #0F172A; padding: 12px; border-radius: 12px; margin-bottom: 12px;">
        <div style="font-size: 12px; color: #94A3B8;">Final Score</div>
        <div id="final-score" style="font-size: 28px; font-weight: 900; color: #38BDF8;">0</div>
        <div style="font-size: 13px; color: #10B981; font-weight: bold; margin-top: 4px;">+<span id="final-coins">0</span> Wallet Coins Earned</div>
      </div>
      <button class="btn-play-again" onclick="restartGame()">Play Again</button>
    </div>
  </div>

  <script>
    const canvas = document.getElementById('gameCanvas');
    const ctx = canvas.getContext('2d');
    
    // Audio Context (Synthesized sound effects, zero external assets)
    let audioCtx = null;
    function playBeep(freq, type = 'sine', duration = 0.1) {
      try {
        if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
        gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + duration);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start();
        osc.stop(audioCtx.currentTime + duration);
      } catch(e) {}
    }

    function resize() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    }
    window.addEventListener('resize', resize);
    resize();

    // Game State
    let score = 0;
    let robuxCoins = 0;
    let stage = 1;
    let isGameOver = false;

    // Player (Blocky Roblox Character)
    const player = {
      x: canvas.width / 2,
      y: 0,
      width: 28,
      height: 44,
      vx: 0,
      vy: 0,
      isGrounded: false,
      color: '#38BDF8'
    };

    // Camera & Platforms
    let cameraY = 0;
    let platforms = [];
    let coins = [];

    function initGame() {
      score = 0;
      robuxCoins = 0;
      stage = 1;
      isGameOver = false;
      document.getElementById('game-over-modal').classList.remove('show');

      player.x = canvas.width / 2;
      player.y = canvas.height - 180;
      player.vx = 0;
      player.vy = 0;
      cameraY = 0;

      platforms = [];
      coins = [];

      // Ground platform
      platforms.push({ x: 0, y: canvas.height - 100, width: canvas.width, height: 40, type: 'safe' });

      // Generate initial tower of platforms
      let curY = canvas.height - 200;
      for (let i = 0; i < 40; i++) {
        const pWidth = Math.max(70, 130 - i * 1.2);
        const pX = Math.random() * (canvas.width - pWidth);
        const isLava = i > 4 && Math.random() < 0.28;
        platforms.push({
          x: pX,
          y: curY,
          width: pWidth,
          height: 18,
          type: isLava ? 'lava' : 'safe'
        });

        // Add Robux Coin on safe platform
        if (!isLava && Math.random() < 0.6) {
          coins.push({
            x: pX + pWidth / 2,
            y: curY - 22,
            radius: 11,
            collected: false
          });
        }
        curY -= (75 + Math.random() * 25);
      }
      updateHUD();
    }

    function updateHUD() {
      document.getElementById('score-val').innerText = score;
      document.getElementById('robux-val').innerText = robuxCoins;
      document.getElementById('stage-val').innerText = stage;
    }

    // Touch controls listeners
    let leftPressed = false;
    let rightPressed = false;

    const bLeft = document.getElementById('btn-left');
    const bRight = document.getElementById('btn-right');
    const bJump = document.getElementById('btn-jump');

    bLeft.addEventListener('touchstart', (e) => { e.preventDefault(); leftPressed = true; bLeft.classList.add('active'); });
    bLeft.addEventListener('touchend', (e) => { e.preventDefault(); leftPressed = false; bLeft.classList.remove('active'); });
    bRight.addEventListener('touchstart', (e) => { e.preventDefault(); rightPressed = true; bRight.classList.add('active'); });
    bRight.addEventListener('touchend', (e) => { e.preventDefault(); rightPressed = false; bRight.classList.remove('active'); });
    bJump.addEventListener('touchstart', (e) => { e.preventDefault(); doJump(); });

    // Keyboard support
    window.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft' || e.key === 'a') leftPressed = true;
      if (e.key === 'ArrowRight' || e.key === 'd') rightPressed = true;
      if (e.key === 'ArrowUp' || e.key === ' ' || e.key === 'w') doJump();
    });
    window.addEventListener('keyup', (e) => {
      if (e.key === 'ArrowLeft' || e.key === 'a') leftPressed = false;
      if (e.key === 'ArrowRight' || e.key === 'd') rightPressed = false;
    });

    function doJump() {
      if (player.isGrounded && !isGameOver) {
        player.vy = -12.5;
        player.isGrounded = false;
        playBeep(440, 'triangle', 0.12);
      }
    }

    function notifyFlutterGameOver() {
      const earnedCoins = Math.max(5, Math.floor(score / 40) + robuxCoins);
      document.getElementById('final-score').innerText = score;
      document.getElementById('final-coins').innerText = earnedCoins;
      document.getElementById('game-over-modal').classList.add('show');
      playBeep(180, 'sawtooth', 0.35);

      // Two-way bridge call to FlutterTNTGameBridge
      try {
        if (window.FlutterTNTGameBridge && window.FlutterTNTGameBridge.postMessage) {
          window.FlutterTNTGameBridge.postMessage(JSON.stringify({
            event: 'GAME_OVER',
            gameId: 'roblox_obby_3d',
            gameTitle: 'Roblox: 3D Obby Parkour',
            score: score,
            coins: earnedCoins
          }));
        }
      } catch(err) {
        console.log('Bridge notification:', err);
      }
    }

    function restartGame() {
      initGame();
    }

    // Main Game Loop (60 FPS)
    function update() {
      if (isGameOver) return;

      // Horizontal physics
      if (leftPressed) player.vx = -5.5;
      else if (rightPressed) player.vx = 5.5;
      else player.vx *= 0.78;

      player.x += player.vx;
      if (player.x < 0) player.x = 0;
      if (player.x > canvas.width - player.width) player.x = canvas.width - player.width;

      // Gravity physics
      player.vy += 0.55;
      player.y += player.vy;
      player.isGrounded = false;

      // Camera smoothly follows player upwards
      const targetCamY = (canvas.height * 0.6) - player.y;
      if (targetCamY > cameraY) {
        cameraY += (targetCamY - cameraY) * 0.1;
      }

      // Platform collision
      for (let p of platforms) {
        if (
          player.x + player.width > p.x &&
          player.x < p.x + p.width &&
          player.y + player.height >= p.y &&
          player.y + player.height <= p.y + 16 &&
          player.vy >= 0
        ) {
          if (p.type === 'lava') {
            isGameOver = true;
            notifyFlutterGameOver();
            return;
          }
          player.y = p.y - player.height;
          player.vy = 0;
          player.isGrounded = true;

          // Award score for climbing higher
          const currentH = Math.floor((canvas.height - 100 - p.y) / 10);
          if (currentH > score) {
            score = currentH;
            stage = Math.floor(score / 50) + 1;
            updateHUD();
          }
        }
      }

      // Coin collection
      for (let c of coins) {
        if (!c.collected) {
          const dx = (player.x + player.width / 2) - c.x;
          const dy = (player.y + player.height / 2) - c.y;
          if (Math.hypot(dx, dy) < 26) {
            c.collected = true;
            robuxCoins += 5;
            score += 20;
            playBeep(880, 'sine', 0.1);
            updateHUD();
          }
        }
      }

      // Check if player fell below camera view
      if (player.y > (canvas.height - cameraY) + 60) {
        isGameOver = true;
        notifyFlutterGameOver();
      }
    }

    let coinRot = 0;
    function render() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.save();
      ctx.translate(0, cameraY);

      // Background Grid / Cyber Obby Horizon
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.04)';
      ctx.lineWidth = 1;
      for (let x = 0; x < canvas.width; x += 40) {
        ctx.beginPath(); ctx.moveTo(x, -5000); ctx.lineTo(x, canvas.height); ctx.stroke();
      }

      // Draw Platforms
      for (let p of platforms) {
        if (p.type === 'lava') {
          // Glowing Neon Lava Platform
          ctx.fillStyle = '#EF4444';
          ctx.shadowColor = '#DC2626';
          ctx.shadowBlur = 12;
          ctx.fillRect(p.x, p.y, p.width, p.height);
          ctx.shadowBlur = 0;
          // Hazard Stripes
          ctx.fillStyle = '#FEF08A';
          ctx.fillRect(p.x + 4, p.y + 4, p.width - 8, 4);
        } else {
          // Roblox 3D Blocky Platform
          ctx.fillStyle = '#38BDF8';
          ctx.fillRect(p.x, p.y, p.width, p.height);
          // 3D Bevel Edge
          ctx.fillStyle = '#0284C7';
          ctx.fillRect(p.x, p.y + p.height - 4, p.width, 4);
        }
      }

      // Draw Coins (Roblox Green Robux Cubes with 3D Spin)
      coinRot += 0.04;
      for (let c of coins) {
        if (!c.collected) {
          ctx.save();
          ctx.translate(c.x, c.y);
          ctx.scale(Math.cos(coinRot), 1);
          ctx.fillStyle = '#10B981';
          ctx.shadowColor = '#34D399';
          ctx.shadowBlur = 8;
          ctx.fillRect(-10, -10, 20, 20);
          ctx.fillStyle = '#FFFFFF';
          ctx.font = 'bold 11px sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText('R\$', 0, 0);
          ctx.restore();
        }
      }

      // Draw Roblox Player (3D Blocky Character: Head, Torso, Legs)
      // Head
      ctx.fillStyle = '#FED7AA';
      ctx.fillRect(player.x + 6, player.y, 16, 14);
      // Cap/Helmet
      ctx.fillStyle = '#0B5CDB';
      ctx.fillRect(player.x + 4, player.y - 3, 20, 6);
      // Eyes
      ctx.fillStyle = '#0F172A';
      ctx.fillRect(player.x + (player.vx >= 0 ? 14 : 8), player.y + 5, 3, 3);
      // Torso (Cyan Roblox Avatar Shirt)
      ctx.fillStyle = '#0284C7';
      ctx.fillRect(player.x + 2, player.y + 14, 24, 18);
      // Roblox Logo on chest
      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(player.x + 10, player.y + 18, 8, 8);
      ctx.fillStyle = '#0284C7';
      ctx.fillRect(player.x + 12, player.y + 20, 4, 4);
      // Legs
      ctx.fillStyle = '#1E293B';
      ctx.fillRect(player.x + 4, player.y + 32, 9, 12);
      ctx.fillRect(player.x + 15, player.y + 32, 9, 12);

      ctx.restore();
    }

    function loop() {
      update();
      render();
      requestAnimationFrame(loop);
    }

    initGame();
    loop();
  </script>
</body>
</html>
''';
  }

  // ---------------------------------------------------------------------------
  // 2. CYBER SPACE SHOOTER (FAST-PACED TOUCH ARCADE)
  // ---------------------------------------------------------------------------
  static String _getSpaceShooterHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Cyber Space Defender</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; touch-action: none; }
    body, html { width: 100%; height: 100%; overflow: hidden; background: #030712; font-family: sans-serif; color: #fff; }
    canvas { width: 100%; height: 100%; display: block; }
    #hud { position: absolute; top: 12px; left: 16px; right: 16px; display: flex; justify-content: space-between; z-index: 10; pointer-events: none; }
    .badge { background: rgba(15, 23, 42, 0.85); padding: 6px 14px; border-radius: 20px; border: 1px solid rgba(255,255,255,0.2); font-weight: bold; font-size: 13px; }
    #modal { display: none; position: absolute; inset: 0; background: rgba(3, 7, 18, 0.9); flex-direction: column; align-items: center; justify-content: center; z-index: 20; }
    #modal.show { display: flex; }
    .card { background: #1F2937; padding: 24px; border-radius: 20px; text-align: center; border: 1px solid #374151; width: 85%; max-width: 320px; }
    .btn { background: #6366F1; color: #fff; border: none; padding: 12px 24px; border-radius: 12px; font-weight: bold; margin-top: 16px; font-size: 15px; width: 100%; }
  </style>
</head>
<body>
  <div id="hud">
    <div class="badge">🚀 Score: <span id="s-val">0</span></div>
    <div class="badge">🛡️ Health: <span id="h-val">100</span>%</div>
  </div>
  <canvas id="c"></canvas>
  <div id="modal">
    <div class="card">
      <div style="font-size: 40px;">🛸</div>
      <h2>Mission Concluded</h2>
      <p style="color: #9CA3AF; font-size: 13px; margin: 8px 0 16px;">Sector cleared of enemy drones!</p>
      <div style="font-size: 26px; font-weight: 900; color: #6366F1;" id="f-score">0</div>
      <button class="btn" onclick="init()">Play Again</button>
    </div>
  </div>
  <script>
    const canvas = document.getElementById('c');
    const ctx = canvas.getContext('2d');
    function resize() { canvas.width = window.innerWidth; canvas.height = window.innerHeight; }
    window.addEventListener('resize', resize); resize();

    let score = 0, health = 100, over = false;
    let ship = { x: canvas.width/2, y: canvas.height - 120, r: 20 };
    let bullets = [], enemies = [], stars = [];

    for (let i = 0; i < 60; i++) stars.push({ x: Math.random()*canvas.width, y: Math.random()*canvas.height, s: Math.random()*2+0.5 });

    function init() {
      score = 0; health = 100; over = false;
      ship.x = canvas.width/2; ship.y = canvas.height - 120;
      bullets = []; enemies = [];
      document.getElementById('modal').classList.remove('show');
      document.getElementById('s-val').innerText = '0';
      document.getElementById('h-val').innerText = '100';
    }

    let touchX = ship.x, touchY = ship.y;
    canvas.addEventListener('touchmove', (e) => {
      e.preventDefault();
      const t = e.touches[0];
      ship.x = t.clientX;
      ship.y = t.clientY - 40;
    });

    let fireTimer = 0;
    function update() {
      if (over) return;
      fireTimer++;
      if (fireTimer % 10 === 0) {
        bullets.push({ x: ship.x, y: ship.y - 20 });
      }

      for (let b of bullets) b.y -= 10;
      bullets = bullets.filter(b => b.y > -20);

      if (Math.random() < 0.04) {
        enemies.push({ x: Math.random()*(canvas.width - 40) + 20, y: -20, vy: Math.random()*2.5 + 2 });
      }

      for (let e of enemies) {
        e.y += e.vy;
        for (let b of bullets) {
          if (Math.hypot(b.x - e.x, b.y - e.y) < 22) {
            e.dead = true; b.dead = true;
            score += 25;
            document.getElementById('s-val').innerText = score;
          }
        }
        if (Math.hypot(ship.x - e.x, ship.y - e.y) < 28) {
          e.dead = true;
          health -= 25;
          document.getElementById('h-val').innerText = Math.max(0, health);
          if (health <= 0) {
            over = true;
            document.getElementById('f-score').innerText = score;
            document.getElementById('modal').classList.add('show');
            try {
              if (window.FlutterTNTGameBridge) {
                window.FlutterTNTGameBridge.postMessage(JSON.stringify({
                  event: 'GAME_OVER',
                  gameId: 'cyber_space_shooter',
                  gameTitle: 'Cyber Space Defender',
                  score: score,
                  coins: Math.max(5, Math.floor(score / 50))
                }));
              }
            } catch(e) {}
          }
        }
      }
      enemies = enemies.filter(e => !e.dead && e.y < canvas.height + 30);
      bullets = bullets.filter(b => !b.dead);
    }

    function render() {
      ctx.fillStyle = '#030712'; ctx.fillRect(0,0,canvas.width, canvas.height);
      ctx.fillStyle = '#fff';
      for (let s of stars) {
        s.y += s.s * 1.5; if (s.y > canvas.height) s.y = 0;
        ctx.fillRect(s.x, s.y, s.s, s.s);
      }

      // Ship
      ctx.fillStyle = '#6366F1';
      ctx.beginPath();
      ctx.moveTo(ship.x, ship.y - 20);
      ctx.lineTo(ship.x - 18, ship.y + 15);
      ctx.lineTo(ship.x + 18, ship.y + 15);
      ctx.fill();

      // Bullets
      ctx.fillStyle = '#38BDF8';
      for (let b of bullets) ctx.fillRect(b.x - 2, b.y, 4, 10);

      // Enemies
      ctx.fillStyle = '#EF4444';
      for (let e of enemies) {
        ctx.beginPath(); ctx.arc(e.x, e.y, 14, 0, Math.PI*2); ctx.fill();
      }
    }

    function loop() { update(); render(); requestAnimationFrame(loop); }
    init(); loop();
  </script>
</body>
</html>
''';
  }

  // ---------------------------------------------------------------------------
  // 3. DIAMOND MERGE 2048
  // ---------------------------------------------------------------------------
  static String _getDiamondMergeHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Diamond Rush 2048</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; touch-action: manipulation; }
    body, html { width: 100%; height: 100%; background: #0F172A; font-family: -apple-system, sans-serif; color: #fff; display: flex; flex-direction: column; align-items: center; justify-content: center; }
    #header { text-align: center; margin-bottom: 16px; }
    .score-box { background: #1E293B; border: 1px solid #334155; padding: 6px 18px; border-radius: 12px; font-size: 16px; font-weight: bold; color: #38BDF8; margin-top: 6px; }
    #grid { width: 300px; height: 300px; background: #1E293B; border-radius: 14px; padding: 8px; display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; border: 2px solid #334155; }
    .cell { background: #0F172A; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 900; transition: all 0.1s; }
    .v2 { background: #0284C7; color: #fff; }
    .v4 { background: #0EA5E9; color: #fff; }
    .v8 { background: #6366F1; color: #fff; }
    .v16 { background: #8B5CF6; color: #fff; }
    .v32 { background: #EC4899; color: #fff; }
    .v64 { background: #F59E0B; color: #fff; }
    .v128 { background: #10B981; color: #fff; font-size: 12px; }
  </style>
</head>
<body>
  <div id="header">
    <h2 style="font-size: 20px;">💎 Diamond Rush</h2>
    <div class="score-box">Score: <span id="score">0</span></div>
  </div>
  <div id="grid"></div>
  <p style="margin-top: 16px; font-size: 12px; color: #94A3B8;">Swipe in any direction to merge diamonds!</p>
  <script>
    let board = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]];
    let score = 0;

    function spawn() {
      let empty = [];
      for(let r=0; r<4; r++) for(let c=0; c<4; c++) if(board[r][c]===0) empty.push({r,c});
      if(empty.length) {
        let p = empty[Math.floor(Math.random()*empty.length)];
        board[p.r][p.c] = Math.random() < 0.9 ? 2 : 4;
      }
    }

    function draw() {
      const g = document.getElementById('grid'); g.innerHTML = '';
      for(let r=0; r<4; r++) {
        for(let c=0; c<4; c++) {
          const d = document.createElement('div');
          d.className = 'cell ' + (board[r][c] ? 'v'+board[r][c] : '');
          d.innerText = board[r][c] ? (board[r][c] + ' 💎') : '';
          g.appendChild(d);
        }
      }
      document.getElementById('score').innerText = score;
    }

    function slide(row) {
      let arr = row.filter(x => x);
      for(let i=0; i<arr.length-1; i++) {
        if(arr[i] === arr[i+1]) {
          arr[i] *= 2; score += arr[i]; arr[i+1] = 0;
        }
      }
      arr = arr.filter(x => x);
      while(arr.length < 4) arr.push(0);
      return arr;
    }

    function move(dir) {
      let changed = false;
      if(dir === 'left' || dir === 'right') {
        for(let r=0; r<4; r++) {
          let row = board[r];
          if(dir === 'right') row.reverse();
          let next = slide(row);
          if(dir === 'right') next.reverse();
          if(board[r].join(',') !== next.join(',')) changed = true;
          board[r] = next;
        }
      }
      if(changed) { spawn(); draw(); }
    }

    // Touch swipe detector
    let startX = 0, startY = 0;
    window.addEventListener('touchstart', e => { startX = e.touches[0].clientX; startY = e.touches[0].clientY; });
    window.addEventListener('touchend', e => {
      let dx = e.changedTouches[0].clientX - startX;
      let dy = e.changedTouches[0].clientY - startY;
      if(Math.abs(dx) > Math.abs(dy)) move(dx > 30 ? 'right' : (dx < -30 ? 'left' : ''));
    });

    spawn(); spawn(); draw();
  </script>
</body>
</html>
''';
  }
}
