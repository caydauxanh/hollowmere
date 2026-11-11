/* HOLLOWMERE — people: jointed figures of realistic proportion, robed, with a procedural walk */
(function () {
  const H = HM.human = {};
  const U = HM.U;
  const std = (c, r) => new THREE.MeshStandardMaterial({ color: c, roughness: r === undefined ? 0.85 : r, metalness: 0 });
  const mesh = (g, m, cast) => { const o = new THREE.Mesh(g, m); o.castShadow = cast !== false; o.receiveShadow = true; return o; };
  const limb = (r, len, m) => { const g = new THREE.CapsuleGeometry(r, len, 3, 8); g.translate(0, -len / 2 - r * 0.4, 0); return mesh(g, m); };

  H.build = (o) => {
    o = Object.assign({ skin: 0xc9a182, robe: 0x2b3147, mantle: 0x1b1f2e, hair: 0x2a2019, boots: 0x1a1512, hat: 'none', scale: 1, belly: 1, beard: false }, o);
    const skin = std(o.skin, 0.7), robe = std(o.robe, 0.92), mantle = std(o.mantle, 0.95), hair = std(o.hair, 0.9), boots = std(o.boots, 0.8);
    robe.side = THREE.DoubleSide; mantle.side = THREE.DoubleSide;
    const root = new THREE.Group(); root.scale.setScalar(o.scale);
    const hips = new THREE.Group(); hips.position.y = 0.93; root.add(hips);
    const torso = new THREE.Group(); hips.add(torso);
    const chest = mesh(new THREE.CapsuleGeometry(0.15, 0.3, 4, 10), robe); chest.position.y = 0.27; chest.scale.set(1.12 * o.belly, 1, 0.78 * o.belly); torso.add(chest);
    const skirt = mesh(new THREE.CylinderGeometry(0.165 * o.belly, 0.27, o.long ? 0.86 : 0.6, 12, 3, true), robe); skirt.position.y = o.long ? -0.3 : -0.18; hips.add(skirt);
    const belt = mesh(new THREE.CylinderGeometry(0.172 * o.belly, 0.176 * o.belly, 0.05, 12), std(0x2a1d12, 0.6), false); belt.position.y = 0.1; belt.scale.z = 0.8; torso.add(belt);
    const cape = mesh(new THREE.CylinderGeometry(0.1, 0.25, 0.26, 12, 1, true), mantle); cape.position.y = 0.45; cape.scale.z = 0.86; torso.add(cape);
    const neck = mesh(new THREE.CylinderGeometry(0.045, 0.055, 0.1, 8), skin, false); neck.position.y = 0.6; torso.add(neck);
    const head = new THREE.Group(); head.position.y = 0.72; torso.add(head);
    const skull = mesh(new THREE.SphereGeometry(0.105, 14, 10), skin); skull.scale.set(0.9, 1.1, 0.98); head.add(skull);
    const nose = mesh(new THREE.ConeGeometry(0.018, 0.045, 5), skin, false); nose.position.set(0, -0.01, 0.105); nose.rotation.x = 1.9; head.add(nose);
    const hr = mesh(new THREE.SphereGeometry(0.112, 12, 8, 0, 6.3, 0, 1.75), hair, false); hr.position.set(0, 0.012, -0.018); hr.rotation.x = -0.35; hr.scale.set(0.93, 1.08, 1.0); head.add(hr);
    if (o.beard) { const b = mesh(new THREE.ConeGeometry(0.07, 0.2, 7), std(o.beard, 0.95), false); b.position.set(0, -0.14, 0.055); b.rotation.x = Math.PI + 0.22; head.add(b); }
    if (o.hat === 'wizard') {
      const hm = std(o.hatCol || o.mantle, 0.9);
      const brim = mesh(new THREE.CylinderGeometry(0.25, 0.27, 0.02, 14), hm); brim.position.y = 0.075; brim.rotation.x = -0.08; head.add(brim);
      const cone = mesh(new THREE.ConeGeometry(0.115, 0.4, 10, 3), hm); cone.position.set(0, 0.27, -0.02); cone.rotation.x = -0.2; head.add(cone);
    } else if (o.hat === 'hood') {
      const hd = mesh(new THREE.SphereGeometry(0.135, 12, 9, 0, 6.3, 0, 2.05), mantle); hd.position.set(0, 0.0, -0.03); hd.rotation.x = -0.5; hd.scale.set(1, 1.12, 1.1); head.add(hd);
    } else if (o.hat === 'cap') {
      const cp = mesh(new THREE.SphereGeometry(0.115, 10, 6, 0, 6.3, 0, 1.3), std(o.hatCol || 0x5a3c26, 0.9)); cp.position.y = 0.02; cp.scale.y = 0.9; head.add(cp);
    } else if (o.hat === 'helm') {
      const he = mesh(new THREE.SphereGeometry(0.122, 12, 8, 0, 6.3, 0, 1.7), new THREE.MeshStandardMaterial({ color: 0x6b7078, roughness: 0.42, metalness: 0.85 })); he.position.y = 0.01; head.add(he);
    }
    const mkArm = (sx) => {
      const sh = new THREE.Group(); sh.position.set(sx * 0.205, 0.47, 0); torso.add(sh);
      sh.add(limb(0.052, 0.26, robe));
      const el = new THREE.Group(); el.position.y = -0.3; sh.add(el);
      el.add(limb(0.044, 0.22, robe));
      const hand = new THREE.Group(); hand.position.y = -0.275; el.add(hand);
      const hm = mesh(new THREE.SphereGeometry(0.042, 8, 6), skin, false); hm.scale.set(0.8, 1.15, 0.6); hand.add(hm);
      return { sh, el, hand };
    };
    const mkLeg = (sx) => {
      const hp = new THREE.Group(); hp.position.set(sx * 0.09, -0.02, 0); hips.add(hp);
      hp.add(limb(0.072, 0.32, boots));
      const kn = new THREE.Group(); kn.position.y = -0.43; hp.add(kn);
      kn.add(limb(0.055, 0.32, boots));
      const ft = mesh(new THREE.BoxGeometry(0.09, 0.07, 0.24), boots); ft.position.set(0, -0.445, 0.055); kn.add(ft);
      return { hp, kn };
    };
    const h = { root, hips, torso, head, chest, skirt, aL: mkArm(-1), aR: mkArm(1), lL: mkLeg(-1), lR: mkLeg(1), phase: Math.random() * 6, amp: 0, carry: false, t: Math.random() * 10, look: 0 };
    return h;
  };

  /* the lamplighter's pole: held in the right hand, lantern swinging from the crook */
  H.givePole = (h) => {
    const wood = std(0x35271c, 0.85), iron = new THREE.MeshStandardMaterial({ color: 0x17181b, roughness: 0.55, metalness: 0.7 });
    const pole = new THREE.Group(); h.aR.hand.add(pole);
    const shaft = mesh(new THREE.CylinderGeometry(0.017, 0.022, 2.0, 6), wood, false); shaft.position.y = 0.3; pole.add(shaft);
    const crook = mesh(new THREE.TorusGeometry(0.13, 0.012, 5, 10, Math.PI), iron, false); crook.position.set(0, 1.3, 0.13); crook.rotation.y = Math.PI / 2; pole.add(crook);
    const hang = new THREE.Group(); hang.position.set(0, 1.3, 0.26); pole.add(hang);
    const lb = HM.lanternBox(true); lb.position.y = -0.24; hang.add(lb);
    const link = mesh(new THREE.CylinderGeometry(0.008, 0.008, 0.1, 4), iron, false); link.position.y = -0.05; hang.add(link);
    h.pole = pole; h.hang = hang; h.lantern = lb; h.carry = true; h.swing = 0; h.swingV = 0;
    return h;
  };

  const q1 = new THREE.Quaternion();
  H.animate = (h, dt, speed, raise) => {
    const a = h.amp = U.damp(h.amp, U.clamp(speed / 2.4, 0, 1.25), 8, dt);
    h.phase += dt * (3.2 + speed * 1.75) * (a > 0.02 ? 1 : 0);
    h.t += dt;
    const s = Math.sin(h.phase), c = Math.cos(h.phase), br = Math.sin(h.t * 1.4);
    h.lL.hp.rotation.x = -s * 0.62 * a; h.lR.hp.rotation.x = s * 0.62 * a;
    h.lL.kn.rotation.x = Math.max(0, c) * 0.95 * a + 0.04; h.lR.kn.rotation.x = Math.max(0, -c) * 0.95 * a + 0.04;
    h.hips.position.y = 0.93 + Math.abs(c) * 0.035 * a - 0.02 * a;
    h.hips.rotation.y = s * 0.09 * a; h.hips.rotation.z = c * 0.025 * a;
    h.torso.rotation.x = 0.07 * a + br * 0.008; h.torso.rotation.y = -s * 0.13 * a;
    h.chest.scale.y = 1 + br * 0.012;
    h.head.rotation.y = U.damp(h.head.rotation.y, h.look, 4, dt) + s * 0.04 * a; h.head.rotation.x = -0.05 * a + br * 0.01;
    h.skirt.rotation.x = 0.05 * a; h.skirt.scale.z = 1 + 0.14 * a;
    h.aL.sh.rotation.x = s * 0.5 * a + 0.04; h.aL.sh.rotation.z = -0.1; h.aL.el.rotation.x = -0.22 - 0.3 * a - Math.max(0, s) * 0.2 * a;
    if (h.carry) {
      const r = h.raise = U.damp(h.raise || 0, raise ? 1 : 0, 6, dt);
      const up = -1.05 - r * 1.15 + c * 0.03 * a, el = -0.42 + r * 0.25;
      h.aR.sh.rotation.x = up; h.aR.sh.rotation.z = 0.12; h.aR.el.rotation.x = el;
      h.pole.rotation.x = -(up + el) - h.torso.rotation.x + 0.26 - r * 0.2;
      // lantern hangs plumb, with a little lag when the walker changes pace
      h.swingV += (-h.swing * 26 - h.swingV * 2.2 + (speed - (h.lastSpeed || 0)) * 3.2 + s * a * 1.3) * dt; h.swing += h.swingV * dt; h.lastSpeed = speed;
      h.hang.parent.getWorldQuaternion(q1); h.hang.quaternion.copy(q1.invert()); h.hang.rotateX(U.clamp(h.swing, -0.5, 0.5) * 0.4);
    } else {
      h.aR.sh.rotation.x = -s * 0.5 * a + 0.04; h.aR.sh.rotation.z = 0.1; h.aR.el.rotation.x = -0.22 - 0.3 * a - Math.max(0, -s) * 0.2 * a;
    }
  };
})();
